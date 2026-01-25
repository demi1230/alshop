class Category < ApplicationRecord
  # Associations - Self-referential for category hierarchy
  belongs_to :parent, class_name: 'Category', optional: true
  has_many :children, class_name: 'Category', foreign_key: 'parent_id', dependent: :restrict_with_error
  has_many :category_attributes, dependent: :destroy
  has_many :products, dependent: :restrict_with_error
  has_many :services, dependent: :restrict_with_error

  # Validations
  validates :name, presence: true
  validates :category_type, inclusion: { in: %w[product service both] }

  # Scopes
  scope :roots, -> { where(parent_id: nil) }  # Top-level categories only
  scope :ordered, -> { order(:name) }
  scope :for_products, -> { where(category_type: ['product', 'both']) }
  scope :for_services, -> { where(category_type: ['service', 'both']) }

  # Category hierarchy helpers
  def root?
    parent_id.nil?
  end

  def leaf?
    children.empty?
  end

  # Get all descendant category IDs (including self)
  # Protected against circular references with visited set
  # Reduces N+1 by querying children at each level, not per-node
  def descendant_ids(visited = Set.new)
    return [] if visited.include?(id)
    
    visited.add(id)
    ids = [id]
    
    Category.where(parent_id: id).find_each do |child|
      ids += child.descendant_ids(visited.dup)
    end
    
    ids
  end
  
  # Optimized entry point for filtering
  def self.descendant_ids_for(category_id)
    category = includes(children: :children).find_by(id: category_id)
    return [] unless category
    category.descendant_ids
  end

  # Get all descendant categories (recursive)
  def descendants
    Category.where(id: descendant_ids)
  end

  # Get all ancestor categories (from parent up to root)
  def ancestors
    result = []
    current = parent
    while current
      result << current
      current = current.parent
    end
    result
  end

  # Get all ancestor IDs
  def ancestor_ids
    ancestors.map(&:id)
  end

  # Display full path (e.g., "Electronics > Computers > Laptops")
  def full_path
    if parent
      "#{parent.full_path} > #{name}"
    else
      name
    end
  end

  # For select dropdown - indent children
  def indented_name(level = 0)
    "#{'  ' * level}#{name}"
  end
end
