# SCALABILITY ANALYSIS: 10M Orders with Read Replicas & Analytics
# Architecture Evaluation for Production Scale
# Date: January 19, 2026

## EXECUTIVE SUMMARY

**What Breaks First:** Revenue::Report (in-memory iteration over potentially millions of orders)
**Critical Path:** Implement materialized views for revenue metrics BEFORE hitting 100K orders
**Stable Boundaries:** ✅ Query/Report separation, ✅ No callbacks, ✅ Service-only architecture

---

## 1. IMMEDIATE BREAKING POINTS (< 100K orders)

### 🔴 CRITICAL: Revenue::Report
**Location:** `app/services/revenue/report.rb`

**Problem:**
```ruby
def total_refunded
  @total_refunded ||= begin
    orders.sum do |order|  # ❌ LOADS ALL ORDERS INTO MEMORY
      refunds = (order.metadata || {})['refunds'] || []
      refunds.sum { |r| (r['amount'] || r[:amount]).to_f }
    end
  end
end

def by_date
  orders.each do |order|  # ❌ ITERATES EVERY ORDER IN RUBY
    # Groups and calculates in-memory
  end
end
```

**Why it breaks:**
- Loads entire result set into Ruby memory
- JSON parsing for EVERY order's metadata
- O(n) complexity for calculations that should be O(1) in SQL
- At 10M orders with 1 month filter = ~300K orders = memory explosion
- No query timeout protection

**Impact Timeline:**
- 10K orders: 2-3 seconds (acceptable)
- 100K orders: 30+ seconds, memory spikes
- 1M orders: Query timeout, OOM crashes
- 10M orders: Complete failure

**Solution Required:** Materialized view with pre-aggregated refunds

---

### 🟡 HIGH RISK: Fulfillments::Queue - Result Object Calculations
**Location:** `app/queries/fulfillments/queue.rb`

**Problem:**
```ruby
def unassigned_count
  fulfillments.count { |f| f.assigned_user_id.nil? }  # ❌ Ruby iteration
end

def by_status
  fulfillments.group_by(&:status).transform_values(&:count)  # ❌ Ruby grouping
end

def overdue
  fulfillments.select { ... }  # ❌ Ruby filtering already-filtered data
end
```

**Why it breaks:**
- Result helper methods iterate in Ruby after database query
- `overdue` and `upcoming` re-filter data that should be SQL-filtered
- At 10K pending fulfillments, this becomes noticeable lag

**Impact Timeline:**
- 1K fulfillments: Acceptable (<100ms)
- 10K fulfillments: 500ms-1s lag in helper methods
- 100K fulfillments: Multi-second response times

**Solution Required:** SQL aggregation, separate count queries with read replica

---

### 🟡 MEDIUM RISK: Orders::List - Deep Pagination
**Location:** `app/queries/orders/list.rb`

**Problem:**
```ruby
relation = relation.offset((@page - 1) * @per_page).limit(@per_page)
```

**Why it breaks:**
- Offset-based pagination doesn't scale
- Page 5000 with per_page=20 = OFFSET 100,000
- Database must scan 100K rows to skip them
- At 10M orders, deep pagination becomes exponentially slower

**Impact Timeline:**
- Page 1-100: Fast (<50ms)
- Page 1000-5000: Slow (500ms-2s)
- Page 10,000+: Very slow (5s+)
- Analytics queries iterating all pages: Complete failure

**Solution Required:** Cursor-based pagination

---

### 🟢 LOW RISK: Orders::List - Email Search
**Location:** `app/queries/orders/list.rb`

**Problem:**
```ruby
relation = relation.joins(:user)
  .where("users.email LIKE ?", "%#{sanitize_like(search_email)}%")
```

**Why it matters:**
- LIKE with leading wildcard can't use indexes
- Full table scan on users table
- With proper indexing (GIN, trigram), this is manageable

**Impact Timeline:**
- With index: Acceptable up to 10M+ users
- Without index: Slow at 100K+ users

**Solution Required:** Full-text search index or pg_trgm extension

---

## 2. ARCHITECTURE BOUNDARIES (Stable vs. Unstable)

### ✅ STABLE BOUNDARIES (Do NOT change)

1. **Query vs. Report Separation**
   - `Revenue::Query` (data) vs `Revenue::Report` (metrics) = EXCELLENT
   - Allows independent scaling strategies
   - Query can hit read replica, Report can use materialized views

2. **Orders::DetailSummary as Value Object**
   - Pure Ruby calculations on single order = scales linearly
   - No N+1 concerns
   - Can be cached independently

3. **No Callbacks / Service-Only Architecture**
   - CRITICAL for scale: No hidden side effects
   - Allows read replicas without fear of writes
   - Clear transaction boundaries

4. **Orders::Detail Single-Record Pattern**
   - Single order lookup with includes() = optimal
   - N+1 prevention is solid
   - Will scale to 10M+ orders with proper indexing

### ❌ UNSTABLE BOUNDARIES (Must change)

1. **In-Memory Aggregation**
   - `Revenue::Report.total_refunded` iterating orders
   - `Fulfillments::Queue` result helpers doing Ruby grouping
   - Must move to SQL or materialized views

2. **Offset Pagination**
   - `Orders::List` using OFFSET/LIMIT
   - Must move to cursor-based pagination

3. **JSON Metadata Parsing in Loops**
   - Revenue calculations parsing every order's metadata
   - Should be extracted to columns or JSONB aggregation

---

## 3. MATERIALIZED VIEWS / READ MODELS REQUIRED

### Priority 1: Revenue Metrics (Implement by 50K orders)

**Table:** `revenue_snapshots`
```sql
CREATE TABLE revenue_snapshots (
  id bigserial PRIMARY KEY,
  date date NOT NULL,
  period_type varchar(10) NOT NULL, -- 'day', 'week', 'month'
  
  -- Metrics
  total_revenue decimal(15,2) NOT NULL DEFAULT 0,
  total_refunded decimal(15,2) NOT NULL DEFAULT 0,
  net_revenue decimal(15,2) NOT NULL DEFAULT 0,
  order_count integer NOT NULL DEFAULT 0,
  
  -- Filters (for partitioning)
  user_id bigint,
  company_id bigint,
  status varchar(50),
  
  created_at timestamp NOT NULL,
  updated_at timestamp NOT NULL,
  
  UNIQUE INDEX idx_revenue_snapshots_lookup (date, period_type, user_id, company_id, status)
);
```

**Refresh Strategy:**
- Incremental: Update when order state changes (via service objects)
- Batch: Nightly recalculation for data consistency
- TTL: 5 minutes for real-time queries

**Impact:**
- Revenue::Report queries drop from seconds to milliseconds
- Analytics warehouse can sync from snapshots table
- Read replicas handle all snapshot reads

---

### Priority 2: Fulfillment Queue Counts (Implement by 100K fulfillments)

**Table:** `fulfillment_queue_stats`
```sql
CREATE TABLE fulfillment_queue_stats (
  id bigserial PRIMARY KEY,
  
  -- Counts by status
  scheduled_count integer DEFAULT 0,
  ongoing_count integer DEFAULT 0,
  unassigned_count integer DEFAULT 0,
  overdue_count integer DEFAULT 0,
  
  -- By assignment
  assigned_to_user_id bigint,
  
  -- Snapshot time
  calculated_at timestamp NOT NULL,
  
  INDEX idx_fulfillment_stats_user (assigned_to_user_id, calculated_at)
);
```

**Refresh Strategy:**
- Real-time: Update on fulfillment state change
- Cache: 30-second TTL for dashboard queries

---

### Priority 3: Order Status Rollups (Implement by 1M orders)

**Table:** `order_status_rollups`
```sql
CREATE TABLE order_status_rollups (
  id bigserial PRIMARY KEY,
  date date NOT NULL,
  status varchar(50) NOT NULL,
  
  user_id bigint,
  company_id bigint,
  
  count integer NOT NULL DEFAULT 0,
  total_value decimal(15,2) NOT NULL DEFAULT 0,
  
  UNIQUE INDEX idx_order_rollups_lookup (date, status, user_id, company_id)
);
```

---

## 4. READ REPLICA STRATEGY

### Queries That MUST Use Read Replicas

1. **Orders::List** - Admin dashboards
   ```ruby
   Order.connection.with_read_replica do
     Orders::List.call(...)
   end
   ```

2. **Revenue::Query** - All revenue reads
   ```ruby
   # In Revenue::Query#call
   scope = Order.connection_pool.with_read_replica do
     Order.all
   end
   ```

3. **Fulfillments::Queue** - Operations dashboard
   ```ruby
   ServiceFulfillment.connection.with_read_replica do
     Fulfillments::Queue.call(...)
   end
   ```

### Queries That Stay on Primary

1. **Orders::Detail** - User-facing, needs latest data
2. **Revenue::Report** when querying snapshots (if snapshots on primary)

### Eventual Consistency Implications

**Problem Areas:**
1. Order just marked paid → User checks order detail → May see "pending" on replica
2. Fulfillment assigned → Dashboard shows unassigned for 1-2 seconds
3. Revenue report → May not include last minute of orders

**Solutions:**
1. Sticky sessions: Route same user to same replica
2. Critical path on primary: Order detail, checkout flow
3. Dashboard staleness indicator: "Data as of 30 seconds ago"

---

## 5. ANALYTICS WAREHOUSE INTEGRATION

### Data Flow Architecture

```
Primary DB (PostgreSQL)
    ↓ (Change Data Capture)
Debezium / Kafka
    ↓ (Stream)
Staging Tables
    ↓ (Transformation)
Data Warehouse (Snowflake/BigQuery/Redshift)
```

### Tables to Replicate

**Hot Path (Real-time CDC):**
1. `orders` - Order lifecycle events
2. `order_items` - Line item analysis
3. `service_fulfillments` - Operations metrics

**Snapshot Path (Daily Batch):**
1. `revenue_snapshots` - Pre-aggregated metrics
2. `order_status_rollups` - Historical rollups
3. `users`, `companies` - Dimension tables

### Query Objects That Should Hit Warehouse

**Move to Warehouse (>6 months historical):**
1. Revenue trends by month/year
2. Customer lifetime value calculations
3. Cohort analysis
4. Attribution reporting

**Keep in App DB (<90 days operational):**
1. Orders::List - Recent orders only
2. Fulfillments::Queue - Active work only
3. Orders::Detail - Current order state

---

## 6. REFACTORING PRIORITY & TIMELINE

### Phase 1: Immediate (Before 100K orders)

**Week 1-2: Revenue::Report Emergency Fix**
- [ ] Create `revenue_snapshots` table
- [ ] Implement incremental snapshot updates in order service objects
- [ ] Refactor `Revenue::Report` to query snapshots
- [ ] Add background job for daily reconciliation

**Week 3: Cursor Pagination**
- [ ] Add `cursor` parameter to Orders::List
- [ ] Implement keyset pagination (id + created_at)
- [ ] Update tests

**Week 4: Read Replica Routing**
- [ ] Configure read replica connection
- [ ] Add `with_read_replica` blocks to query objects
- [ ] Test replication lag handling

### Phase 2: Optimization (100K-1M orders)

**Month 2:**
- [ ] Implement `fulfillment_queue_stats`
- [ ] Refactor Fulfillments::Queue result helpers
- [ ] Add JSONB indexes on order.metadata for refund queries
- [ ] Implement full-text search for email search

**Month 3:**
- [ ] Create `order_status_rollups`
- [ ] Set up CDC pipeline to analytics warehouse
- [ ] Archive orders older than 2 years to cold storage

### Phase 3: Scale (1M-10M orders)

**Quarter 2:**
- [ ] Partition orders table by created_at (monthly partitions)
- [ ] Implement hot/warm/cold data tiering
- [ ] Move historical queries to warehouse
- [ ] Implement caching layer (Redis) for common queries

---

## 7. MONITORING & ALERTS

### Critical Metrics to Track

**Query Performance:**
```ruby
# Add to ApplicationController or middleware
ActiveSupport::Notifications.subscribe('sql.active_record') do |*args|
  event = ActiveSupport::Notifications::Event.new(*args)
  if event.duration > 1000 # 1 second
    Rails.logger.warn("SLOW QUERY: #{event.payload[:sql]}")
    # Alert to PagerDuty
  end
end
```

**Alert Thresholds:**
1. Revenue::Report query > 5 seconds → P1 alert
2. Orders::List p95 > 1 second → P2 alert
3. Fulfillments::Queue p95 > 500ms → P3 alert
4. Read replica lag > 30 seconds → P1 alert

**Capacity Planning:**
| Metric | Current | 100K | 1M | 10M |
|--------|---------|------|-----|-----|
| Orders::List p95 | 50ms | 200ms | 500ms | 2s* |
| Revenue::Report | 100ms | 30s** | FAIL | FAIL |
| Revenue::Report (with snapshots) | - | 50ms | 100ms | 200ms |
| Fulfillments::Queue | 80ms | 300ms | 1s | 5s* |

\* With cursor pagination
\** Without snapshots - unacceptable

---

## 8. CODE CHANGES REQUIRED

### Revenue::Report - Rewrite to Use Snapshots

**New file:** `app/services/revenue/snapshot_updater.rb`
```ruby
module Revenue
  class SnapshotUpdater
    # Called from order service objects after state changes
    def self.update_for_order(order)
      date = order.created_at.to_date
      
      RevenueSnapshot.upsert_all(
        generate_snapshot_rows(order),
        unique_by: [:date, :period_type, :user_id, :company_id, :status]
      )
    end
    
    private
    
    def self.generate_snapshot_rows(order)
      # Calculate refunds from order.metadata
      refunds = extract_refunds(order)
      
      %w[day week month].map do |period_type|
        period_date = order.created_at.to_date.public_send("beginning_of_#{period_type}")
        
        {
          date: period_date,
          period_type: period_type,
          user_id: order.user_id,
          company_id: order.user.company_id,
          status: order.status,
          total_revenue: order.total_price,
          total_refunded: refunds,
          net_revenue: order.total_price - refunds,
          order_count: 1
        }
      end
    end
  end
end
```

**Modified:** `app/services/revenue/report.rb`
```ruby
# Query snapshots instead of orders
def call
  snapshots = RevenueSnapshot
    .where(period_type: @group_by || 'day')
    .where(date: @from_date..@to_date)
  
  # Filter by dimensions
  snapshots = snapshots.where(user_id: @user_id) if @user_id
  snapshots = snapshots.where(company_id: @company_id) if @company_id
  snapshots = snapshots.where(status: @status) if @status
  
  Result.new(snapshots: snapshots)
end

class Result
  def total_revenue
    @total_revenue ||= snapshots.sum(:total_revenue)  # SQL aggregation
  end
  
  def total_refunded
    @total_refunded ||= snapshots.sum(:total_refunded)  # SQL aggregation
  end
  
  # No Ruby iteration!
end
```

### Orders::List - Add Cursor Pagination

```ruby
def call
  relation = build_base_query
  relation = apply_filters(relation)
  relation = apply_ordering(relation)
  
  if @cursor.present?
    relation = apply_cursor(relation)  # NEW
    paginated = relation.limit(@per_page)
  else
    # Fallback to offset for first page only
    paginated = relation.offset(0).limit(@per_page)
  end
  
  # ...
end

def apply_cursor(relation)
  # Cursor format: "#{created_at.to_i}_#{id}"
  timestamp, id = @cursor.split('_')
  cursor_time = Time.at(timestamp.to_i)
  
  relation.where(
    '(orders.created_at, orders.id) < (?, ?)',
    cursor_time,
    id.to_i
  )
end
```

---

## 9. FINAL RECOMMENDATIONS

### DO THIS IMMEDIATELY (Before Production)
1. ✅ Keep current Query/Report separation - it's PERFECT for scaling
2. ❌ Rewrite Revenue::Report to use materialized snapshots
3. ✅ Add read replica routing with 5-second lag tolerance
4. ✅ Implement cursor pagination in Orders::List
5. ❌ Add query timeout: `config.active_record.query_timeout = 5000 # 5s`

### DO THIS BY 100K ORDERS
1. Extract refund amounts to dedicated column or JSONB index
2. Implement fulfillment queue stats table
3. Add comprehensive slow query monitoring
4. Set up analytics warehouse pipeline

### ARCHITECTURAL STRENGTHS (Keep These!)
1. ✅ No callbacks = Clean read replica strategy
2. ✅ Service objects = Clear write path for CDC
3. ✅ Query/Report split = Perfect for snapshot strategy
4. ✅ Value objects (DetailSummary) = Efficient single-record operations
5. ✅ Explicit transactions = No hidden complexity

### ARCHITECTURAL RISKS
1. ❌ Metadata JSON parsing in loops = Show-stopper at scale
2. ❌ Ruby-land aggregations = Must move to SQL
3. ❌ Offset pagination = Deep pages will timeout
4. ⚠️ No caching layer = Every request hits database

---

## 10. ESTIMATED COSTS AT 10M ORDERS

**Without Optimizations:**
- Database: Overloaded, query timeouts
- Memory: OOM crashes on revenue reports
- Response time: 5-30 second page loads
- **Result: Service unavailable**

**With Optimizations:**
- Database: Read replicas + materialized views = $2K/month
- Cache layer: Redis cluster = $500/month
- Analytics warehouse: Snowflake/BigQuery = $1K/month
- CDN/edge caching: CloudFlare = $200/month
- **Total: ~$3.7K/month for 10M orders**

**Performance:**
- Orders::List: 50-200ms (cursor pagination)
- Orders::Detail: 20-50ms (single record)
- Revenue::Report: 50-100ms (snapshot queries)
- Fulfillments::Queue: 100-200ms (stats table)
- **Result: Acceptable performance at scale**
