namespace :categories do
  desc "Assign category types to existing categories"
  task assign_types: :environment do
    puts "Assigning category types..."
    
    # Set Програм хангамж as service-only
    service_categories = ["Програм хангамж"]
    
    # Update service categories
    service_categories.each do |name|
      category = Category.roots.find_by(name: name)
      if category
        category.update(category_type: 'service')
        puts "✓ Set '#{name}' as service category"
      end
    end
    
    # Set all other root categories as product-only
    Category.roots.where.not(name: service_categories).each do |category|
      category.update(category_type: 'product')
      puts "✓ Set '#{category.name}' as product category"
    end
    
    puts "\nDone!"
    puts "\nCurrent breakdown:"
    puts "  Product-only: #{Category.roots.where(category_type: 'product').count}"
    puts "  Service-only: #{Category.roots.where(category_type: 'service').count}"
    puts "  Both: #{Category.roots.where(category_type: 'both').count}"
  end
end
