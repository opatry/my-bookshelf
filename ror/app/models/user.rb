class User < ApplicationRecord
  include Sanitizable

  has_secure_password

  has_many :reviews, dependent: :destroy
  has_many :books, through: :reviews

  sanitizes :name

  validates :name, presence: true
  validates :email, presence: true, uniqueness: true
end
