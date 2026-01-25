class AddLeafCategoryCheck < ActiveRecord::Migration[8.0]
  def up
    # Add check constraint: products.category_id must reference a leaf category
    # This prevents data corruption at database level
    # 
    # Note: SQLite doesn't support subqueries in CHECK constraints
    # Use triggers or application-level validation instead
    #
    # For PostgreSQL/MySQL:
    # execute <<-SQL
    #   ALTER TABLE products
    #   ADD CONSTRAINT products_category_must_be_leaf
    #   CHECK (
    #     NOT EXISTS (
    #       SELECT 1 FROM categories 
    #       WHERE parent_id = products.category_id
    #     )
    #   )
    # SQL
    
    # SQLite alternative: Add trigger
    if ActiveRecord::Base.connection.adapter_name == 'SQLite'
      execute <<-SQL
        CREATE TRIGGER prevent_parent_category_assignment
        BEFORE INSERT ON products
        FOR EACH ROW
        WHEN NEW.category_id IS NOT NULL
          AND EXISTS (SELECT 1 FROM categories WHERE parent_id = NEW.category_id)
        BEGIN
          SELECT RAISE(ABORT, 'Products can only be assigned to leaf categories');
        END;
      SQL
      
      execute <<-SQL
        CREATE TRIGGER prevent_parent_category_update
        BEFORE UPDATE ON products
        FOR EACH ROW
        WHEN NEW.category_id IS NOT NULL
          AND EXISTS (SELECT 1 FROM categories WHERE parent_id = NEW.category_id)
        BEGIN
          SELECT RAISE(ABORT, 'Products can only be assigned to leaf categories');
        END;
      SQL

      execute <<-SQL
        CREATE TRIGGER prevent_parent_category_assignment_services
        BEFORE INSERT ON services
        FOR EACH ROW
        WHEN NEW.category_id IS NOT NULL
          AND EXISTS (SELECT 1 FROM categories WHERE parent_id = NEW.category_id)
        BEGIN
          SELECT RAISE(ABORT, 'Services can only be assigned to leaf categories');
        END;
      SQL

      execute <<-SQL
        CREATE TRIGGER prevent_parent_category_update_services
        BEFORE UPDATE ON services
        FOR EACH ROW
        WHEN NEW.category_id IS NOT NULL
          AND EXISTS (SELECT 1 FROM categories WHERE parent_id = NEW.category_id)
        BEGIN
          SELECT RAISE(ABORT, 'Services can only be assigned to leaf categories');
        END;
      SQL
    end
  end

  def down
    if ActiveRecord::Base.connection.adapter_name == 'SQLite'
      execute "DROP TRIGGER IF EXISTS prevent_parent_category_assignment"
      execute "DROP TRIGGER IF EXISTS prevent_parent_category_update"
      execute "DROP TRIGGER IF EXISTS prevent_parent_category_assignment_services"
      execute "DROP TRIGGER IF EXISTS prevent_parent_category_update_services"
    else
      execute "ALTER TABLE products DROP CONSTRAINT IF EXISTS products_category_must_be_leaf"
    end
  end
end
