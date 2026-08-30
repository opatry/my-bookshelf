class Tag < ApplicationRecord
  include Sanitizable

  has_many :book_tags, dependent: :destroy
  has_many :books, through: :book_tags

  sanitizes :name

  validates :name, presence: true, uniqueness: true
  validates :slug, presence: true, uniqueness: true

  before_validation :set_slug

  # Tag URLs take the form /tags/:slug.
  def to_param
    slug
  end

  private

  def set_slug
    self.slug = name.to_s.parameterize if slug.blank? || name_changed?
  end
end
