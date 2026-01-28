# Service System - User Journey Guide

## 🎯 Хэрэглэгчийн үйлдлийн гарын авлага

---

## 1️⃣ **Үйлчилгээ хайх** (Service Browsing)

### URL: `/services`

### Хэрэглэгч юу харах вэ?
- **Үйлчилгээний жагсаалт**: Grid layout (3 columns desktop)
- **Шүүлт цонх**: Left sidebar with category filter
- **Хайлтын талбар**: Search by service name
- **Үйлчилгээ бүрт**:
  - Нэр (clickable)
  - Тайлбар (line-clamp-2)
  - Үндсэн үнэ (base_price)
  - "Дэлгэрэнгүй" товч

### Хэрэглэгчийн үйлдлүүд:
1. ✅ Ангиллаар шүүх (category filter)
2. ✅ Үйлчилгээ хайх (search)
3. ✅ "Дэлгэрэнгүй" дарж дэлгэрэнгүй харах
4. ✅ Pagination - хуудас солих

---

## 2️⃣ **Үйлчилгээний дэлгэрэнгүй** (Service Detail)

### URL: `/services/:id`

---

### 🔧 **Scenario A: Цагаар тооцдог үйлчилгээ (Hourly Service)**

**Жишээ:** "ERP Customization & Support" - IT дэмжлэг

#### Хэрэглэгч юу харах вэ?
```
┌─────────────────────────────────────────┐
│  ERP Customization & Support            │
│  ┌─────────────┐                        │
│  │   Цагаар    │  ← Service type badge  │
│  └─────────────┘                        │
│                                         │
│  💡 Тохиргоо:                           │
│  ┌─────────────────────────────────┐   │
│  │ Support Level:                  │   │
│  │ [ Standard ]  [ Premium ]       │   │ ← Config options
│  │     +0₮        +60,000₮         │   │
│  └─────────────────────────────────┘   │
│                                         │
│  📊 Үнэ тооцоолол:                      │
│  Үндсэн үнэ:      120,000₮/цаг         │
│  Тохиргоо:        +60,000₮             │ (if Premium selected)
│  ──────────────────────────────        │
│  Нийт:            180,000₮             │
│                                         │
│  ⏱ Цагийн тоо:                          │
│     [ - ]   3   [ + ]                   │ ← Quantity selector
│                                         │
│  💰 Нийт төлбөр:  540,000₮             │ (180k × 3)
│                                         │
│  [    🛒 Сагслах    ]                   │ ← Add to Cart
│  [      Буцах       ]                   │
└─────────────────────────────────────────┘
```

#### Хэрэглэгчийн үйлдлүүд:
1. ✅ **Config option сонгох**: "Premium" дарах → үнэ +60,000₮
2. ✅ **Цагийн тоо сонгох**: [ + ] дарж 3 болгох → 540,000₮
3. ✅ **Real-time price update**: Автоматаар тооцоолох
4. ✅ **"Сагслах" дарах**: CartItem үүсгэх
   - `sellable_id`: Service-ийн sellable_id
   - `quantity`: 3
   - `configuration`: `{"spec_id": {"value": "Premium", "unit_price": 60000}}`

---

### 📦 **Scenario B: Тогтмол үнэтэй үйлчилгээ (Fixed Service)**

**Жишээ:** "Toyota Full Service Package" - Машины засвар

#### Хэрэглэгч юу харах вэ?
```
┌─────────────────────────────────────────┐
│  Toyota Full Service Package            │
│  ┌──────────────────┐                   │
│  │  Тогтмол үнэтэй  │                   │
│  │ Цаг товлох шаардлагатай              │
│  └──────────────────┘                   │
│                                         │
│  📝 Тайлбар:                            │
│  Иж бүрэн техникийн үзлэг, засвар       │
│  үйлчилгээ. Toyota Mongolia-ийн         │
│  баталгаажсан механикууд.               │
│                                         │
│  💰 Үнэ: 150,000₮                       │
│                                         │
│  📊 Тоо ширхэг:                         │
│     [ - ]   1   [ + ]                   │
│                                         │
│  [    🛒 Сагслах    ]                   │
│  [      Буцах       ]                   │
└─────────────────────────────────────────┘
```

#### Хэрэглэгчийн үйлдлүүд:
1. ✅ **Quantity select**: Default 1 (өөрчлөх боломжтой)
2. ✅ **"Сагслах" дарах**: Add to cart
3. ✅ **Cart-руу шилжих**: `/cart`
4. ✅ **Checkout**: Order үүсгэх
5. ✅ **Service Fulfillment**: Цаг товлолт шаардлагатай

---

### 🔄 **Scenario C: Захиалгат үйлчилгээ (Subscription Service)**

**Жишээ:** "Xerox ERP Enterprise Package" - ERP систем

#### Хэрэглэгч юу харах вэ?
```
┌─────────────────────────────────────────┐
│  Xerox ERP Enterprise Package           │
│  ┌─────────────┐                        │
│  │  Захиалгат  │                        │
│  └─────────────┘                        │
│                                         │
│  📋 Захиалгын төлөвлөгөө:               │
│  ┌─────────────────────────────────┐   │
│  │ ┌─────────────────────────────┐ │   │
│  │ │  📅 Сарын төлөвлөгөө         │ │   │
│  │ │  5,000,000₮ /сар             │ │ ← Selected (blue border)
│  │ │  🎁 7 хоног үнэгүй туршилт   │ │   │
│  │ └─────────────────────────────┘ │   │
│  │                                 │   │
│  │ ┌─────────────────────────────┐ │   │
│  │ │  📆 Жилийн төлөвлөгөө        │ │   │
│  │ │  50,000,000₮ /жил            │ │   │
│  │ │  (-16% хөнгөлөлт)            │ │   │
│  │ │  🎁 30 хоног үнэгүй туршилт  │ │   │
│  │ └─────────────────────────────┘ │   │
│  └─────────────────────────────────┘   │
│                                         │
│  💡 Тохиргоо:                           │
│  ┌─────────────────────────────────┐   │
│  │ User count: [___10___]          │   │ ← Input field
│  │   Нэмэлт үнэ: 50,000₮/user      │   │
│  │                                 │   │
│  │ Extra module:                   │   │
│  │ [✓] Идэвхжүүлэх                 │   │ ← Checkbox
│  │   Нэмэлт үнэ: 300,000₮          │   │
│  └─────────────────────────────────┘   │
│                                         │
│  💰 Үнэ тооцоолол:                      │
│  Сарын үнэ:        5,000,000₮          │
│  User count:         500,000₮          │ (10 × 50k)
│  Extra module:       300,000₮          │
│  ──────────────────────────────        │
│  Сард нийт:        5,800,000₮          │
│                                         │
│  [      ➕ Захиалах      ]  ← Subscribe │
│  [         Буцах         ]             │
└─────────────────────────────────────────┘
```

#### Хэрэглэгчийн үйлдлүүд:

1. ✅ **Subscription plan сонгох**: "Сарын төлөвлөгөө" дарах
   - Plan card blue border болох
   - "Захиалах" товч идэвхтэй болох
   - Үнэ 5,000,000₮ болж шинэчлэгдэх

2. ✅ **Config оруулах**: 
   - User count: 10 оруулах → +500,000₮
   - Extra module: Check хийх → +300,000₮
   - Real-time price: 5,800,000₮

3. ✅ **"Захиалах" дарах**:
   - POST `/subscriptions`
   - UserSubscription үүсгэх:
     ```ruby
     {
       user_id: current_user.id,
       subscription_plan_id: selected_plan_id,
       status: 'active',
       start_date: Date.current,
       configuration: {
         "user_count": {"value": 10, "unit_price": 50000},
         "extra_module": {"value": true, "unit_price": 300000}
       }
     }
     ```
   - Redirect to `/subscriptions`

---

## 3️⃣ **Захиалга удирдах** (Subscription Management)

### URL: `/subscriptions`

#### Хэрэглэгч юу харах вэ?
```
┌────────────────────────────────────────────┐
│  Миний захиалгууд                          │
│  Таны идэвхтэй болон хүчингүй болсон       │
│  захиалгуудын жагсаалт                     │
│                                            │
│  ┌─────────────────────────────────────┐  │
│  │ Xerox ERP Enterprise Package        │  │
│  │                    [ Идэвхтэй ]     │  │ ← Green badge
│  │                                     │  │
│  │ 5,800,000₮ /сар                     │  │
│  │ ───────────────────────────────     │  │
│  │ Эхэлсэн огноо:    2026-01-27        │  │
│  │ Төлбөрийн давтамж: Сар бүр          │  │
│  │ Туршилтын хугацаа: 7 хоног          │  │
│  │                                     │  │
│  │ [        Цуцлах        ]            │  │ ← Cancel button
│  └─────────────────────────────────────┘  │
│                                            │
│  ┌─────────────────────────────────────┐  │
│  │ Toyota Service Package              │  │
│  │                  [ Цуцлагдсан ]     │  │ ← Red badge
│  │                                     │  │
│  │ 150,000₮ /сар                       │  │
│  │ ───────────────────────────────     │  │
│  │ Эхэлсэн огноо:    2025-12-01        │  │
│  │ Дууссан огноо:    2026-01-15        │  │
│  │ Төлбөрийн давтамж: Сар бүр          │  │
│  └─────────────────────────────────────┘  │
└────────────────────────────────────────────┘
```

#### Хэрэглэгчийн үйлдлүүд:

1. ✅ **Захиалга харах**: Бүх subscription жагсаалт
2. ✅ **Идэвхтэй захиалга**: Green badge, "Цуцлах" товчтой
3. ✅ **"Цуцлах" дарах**:
   - Confirm modal: "Та итгэлтэй байна уу?"
   - PATCH `/subscriptions/:id/cancel`
   - Update: `status: 'cancelled', end_date: Date.current`
   - Subscription card red badge болох

---

## 🔄 Complete User Flow Diagram

```
┌──────────────┐
│   Homepage   │
└──────┬───────┘
       │
       ↓
┌──────────────────────┐
│  /services (Browse)  │  ← Service listing with filters
└──────┬───────────────┘
       │
       │ Click "Дэлгэрэнгүй"
       ↓
┌────────────────────────────────────────────┐
│        /services/:id (Detail)              │
│                                            │
│   ┌─────────────────┬─────────────────┐   │
│   │ Hourly/Fixed    │  Subscription   │   │
│   └────────┬────────┴────────┬────────┘   │
│            │                 │            │
│            ↓                 ↓            │
│    ┌──────────────┐   ┌──────────────┐   │
│    │ Configure &  │   │ Select Plan  │   │
│    │ Add to Cart  │   │ & Subscribe  │   │
│    └──────┬───────┘   └──────┬───────┘   │
└───────────┼──────────────────┼───────────┘
            │                  │
            ↓                  ↓
    ┌──────────────┐   ┌──────────────────┐
    │    /cart     │   │  /subscriptions  │
    └──────┬───────┘   └──────────────────┘
           │
           ↓
    ┌──────────────┐
    │   Checkout   │
    │   /orders    │
    └──────────────┘
```

---

## 🎨 UI Components Used

### Buttons:
- **Primary:** `px-2 py-2 bg-[#0053E2] hover:bg-[#003299] text-white rounded-lg`
- **Secondary:** `px-2 py-2 border border-gray-300 text-gray-700 rounded-lg`
- **Danger:** `px-2 py-2 border border-red-300 text-red-700 rounded-lg`

### Badges:
- **Active:** `px-3 py-1 rounded-full bg-green-100 text-green-800`
- **Inactive:** `px-3 py-1 rounded-full bg-red-100 text-red-800`
- **Service Type:** `px-3 py-1 rounded-full bg-blue-100 text-blue-800`

### Cards:
- **Default:** `bg-white rounded-lg shadow-sm border border-gray-200 p-6`
- **Selected:** `border-[#0053E2] bg-blue-50`

---

## 📊 Data Flow

### Service Configuration → Cart Item
```ruby
# User input in UI
{
  "user_count": 10,
  "extra_module": true,
  "support_level": "Premium"
}

# Transformed with prices
{
  "spec_123": {
    "value": 10,
    "unit_price": 50000
  },
  "spec_124": {
    "value": true,
    "unit_price": 300000
  },
  "spec_125": {
    "value": "Premium",
    "unit_price": 60000
  }
}

# Stored in cart_item.configuration (JSON field)
```

### Price Calculation
```javascript
basePrice = sellable.base_price      // 120,000₮
quantity = 3                         // 3 цаг
configPrice = Σ(unit_price)          // 410,000₮

totalPrice = (basePrice × quantity) + configPrice
           = (120,000 × 3) + 410,000
           = 360,000 + 410,000
           = 770,000₮
```

---

## ✅ Implementation Complete

### Хэрэгжсэн функцүүд:
1. ✅ Service browsing with filters
2. ✅ Service detail with configuration
3. ✅ Real-time price calculation
4. ✅ Add to cart (hourly/fixed services)
5. ✅ Subscription plan selection
6. ✅ Direct subscription (subscription services)
7. ✅ Subscription management
8. ✅ Cancel subscription
9. ✅ Responsive UI (mobile/desktop)
10. ✅ Mongolian localization

### Дараа хэрэгжүүлэх:
- [ ] Payment integration (subscription billing)
- [ ] Service scheduling calendar
- [ ] Inventory/availability check
- [ ] Service fulfillment workflow
- [ ] Reviews and ratings
- [ ] Service images/gallery
