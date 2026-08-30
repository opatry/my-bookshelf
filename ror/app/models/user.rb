class User < ApplicationRecord
  include Sanitizable

  has_secure_password

  has_many :reviews, dependent: :destroy
  has_many :books, through: :reviews

  sanitizes :name

  validates :name, presence: true
  validates :email, presence: true, uniqueness: true

  # Phase 1 is single-user: the public site and admin act on this owner's
  # reviews. Phase 2 replaces this with authentication.
  def self.default_owner
    find_by(email: ENV.fetch("DEFAULT_USER_EMAIL", "olivier@example.org"))
  end
end
