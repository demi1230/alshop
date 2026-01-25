class User < ApplicationRecord
  # Devise modules - standard Rails authentication
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  # Associations
  belongs_to :company, optional: true
  has_many :carts, dependent: :destroy
  has_many :orders, dependent: :nullify
  has_many :user_subscriptions, dependent: :destroy
  has_many :subscription_plans, through: :user_subscriptions
  has_many :assigned_service_fulfillments, class_name: 'ServiceFulfillment', foreign_key: 'assigned_user_id', dependent: :nullify

  # Validations (Devise handles email/password validation)
  validates :role, presence: true, inclusion: { in: %w[admin customer staff] }

  # Enums
  enum :role, { customer: 'customer', staff: 'staff', admin: 'admin' }, validate: true, default: 'customer'

  # Role helper methods
  def admin?
    role == 'admin'
  end

  def customer?
    role == 'customer'
  end

  def staff?
    role == 'staff'
  end

  # Ensure user has an active cart
  after_create :create_cart_if_needed

  private

  def create_cart_if_needed
    create_cart!(status: :active) unless cart.present?
  end
end
