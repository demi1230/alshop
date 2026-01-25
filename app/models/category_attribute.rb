class CategoryAttribute < ApplicationRecord
  # Associations
  belongs_to :category
  has_many :specifications, dependent: :destroy

  # Validations
  validates :name, presence: true
  validates :is_required, inclusion: { in: [true, false] }
end
