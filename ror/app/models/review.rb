class Review < ApplicationRecord
  belongs_to :user
  belongs_to :book

  enum :status, { read: 0, wishlist: 1, ongoing: 2 }

  validates :status, presence: true
  validates :rating, inclusion: { in: 1..10 }, if: :read?
  validates :priority, numericality: { only_integer: true, greater_than: 0 }, if: :wishlist?
  validates :book_id, uniqueness: { scope: :user_id }

  validate :read_review_requires_rating_and_date
  validate :ongoing_review_has_no_rating_nor_date

  before_validation :normalize_status_fields

  scope :recent, -> { order(read_date: :desc, id: :desc) }
  scope :favorites, -> { where(favorite: true) }
  scope :rated, -> { where.not(rating: nil) }
  scope :with_book, -> { includes(book: [ :tags, cover_attachment: :blob ]) }

  private

  # Keep the record consistent when the status changes: switp to wishlist or
  # ongoing drops the reading facts; read drops the priority.
  def normalize_status_fields
    case status&.to_sym
    when :read
      self.priority = nil
    when :ongoing
      self.priority = nil
      self.rating = nil
      self.read_date = nil
    when :wishlist
      self.rating = nil
      self.read_date = nil
    end
  end

  def read_review_requires_rating_and_date
    return unless read?

    errors.add(:rating, :blank) if rating.blank?
    errors.add(:read_date, :blank) if read_date.blank?
  end

  def ongoing_review_has_no_rating_nor_date
    return unless ongoing?

    errors.add(:rating, :must_be_blank) if rating.present?
    errors.add(:read_date, :must_be_blank) if read_date.present?
  end
end
