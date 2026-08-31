class Book < ApplicationRecord
  include Sanitizable

  attr_accessor :tag_names

  belongs_to :series, optional: true

  has_many :reviews, dependent: :destroy
  has_many :book_tags, dependent: :destroy
  has_many :tags, through: :book_tags
  has_one_attached :cover do |attachable|
    attachable.variant :mini, resize_to_limit: [ 50, 75 ]
    attachable.variant :medium, resize_to_limit: [ 75, 112 ]
    attachable.variant :default, resize_to_limit: [ 150, 225 ]
    attachable.variant :showcase, resize_to_limit: [ 300, 450 ]
  end

  sanitizes :title, :author, :description

  before_save :set_search_text

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

  # Tag editing from the admin form: a comma/semicolon-separated list of names
  # turned into the tags association right before saving.
  def tag_names
    @tag_names.presence || tags.map(&:name).join(", ")
  end

  def tags_from_names!
    names = @tag_names.to_s.split(/[,;]/).map(&:strip).reject(&:empty?).uniq
    self.tags = names.map { |name| Tag.find_or_create_by!(name: name) }
  end

  # Public URLs take the form /books/:id-:slug (id is the canonical part).
  def to_param
    [ id, slug ].join("-")
  end

  def formatted_isbn
    Isbn13.new(isbn).formatted
  end

  private

  # Maintains the portable, accent/quote-insensitive search vector from the
  # current title, author and tags. Runs in Ruby via `SearchNormalizer`, so it
  # behaves identically on any database engine.
  def set_search_text
    self.search_text = SearchNormalizer.normalize([ title, author, tags.map(&:name) ].flatten.join(" "))
  end
end
