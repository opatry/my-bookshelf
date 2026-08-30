class Book < ApplicationRecord
  include Sanitizable

  belongs_to :series, optional: true

  has_many :reviews, dependent: :destroy
  has_many :book_tags, dependent: :destroy
  has_many :tags, through: :book_tags
  has_one_attached :cover

  sanitizes :title, :author, :description

  validates :title, presence: true
  validates :author, presence: true
  validates :isbn, presence: true, uniqueness: true, isbn13: true

  # Books never belong to a user directly; they are shared. Reverse side of
  # the review relationship is provided for convenience.
  scope :with_cover, -> { joins(:cover_attachment) }
  scope :by_title, -> { order(:title) }

  # Slug used as an optional, human-friendly suffix in public URLs.
  def slug
    title.to_s.parameterize
  end

  def formatted_isbn
    Isbn13.new(isbn).formatted
  end
end
