module ApplicationHelper
  # Calculate discount percentage for a product based on pricing rules
  def calculate_discount(product)
    return nil unless product
    return nil unless product.is_a?(Product)
    
    sellable = product.sellable
    return nil unless sellable
    
    # Find applicable pricing rules for this sellable
    # Check if there are any active pricing rules (within valid date range)
    applicable_rules = PricingRule.where(sellable_id: sellable.id)
      .where(discount_type: "percentage")
      .where("valid_from IS NULL OR valid_from <= ?", Time.current)
      .where("valid_to IS NULL OR valid_to >= ?", Time.current)
    
    return nil if applicable_rules.empty?
    
    # Get the maximum discount value
    max_discount = applicable_rules.maximum(:value)
    
    max_discount&.to_i
  end
  
  # Format price in Mongolian Tugrik
  def format_tugrik(amount)
    number_to_currency(amount, unit: "₮", precision: 0, format: "%n%u")
  end
  
  # Generate hierarchical category options for select dropdown
  # Shows all categories with indentation, but only leaf categories are selectable
  def hierarchical_category_options(categories_collection = nil, selected_id = nil)
    categories = categories_collection || Category.roots.includes(children: :children)
    options = []
    
    categories.each do |category|
      build_category_options(category, options, 0)
    end
    
    options_for_select(options, selected_id)
  end
  
  private
  
  def build_category_options(category, options, level)
    # Add current category
    indent = '　' * level  # Japanese space for better visual indentation
    label = "#{indent}#{category.name}"
    
    if category.leaf?
      # Leaf category - selectable
      options << [label, category.id]
    else
      # Parent category - disabled
      options << [label + " (folder)", nil, { disabled: true }]
    end
    
    # Recursively add children
    category.children.ordered.each do |child|
      build_category_options(child, options, level + 1)
    end
  end
end

