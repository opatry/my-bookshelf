class Series < ApplicationRecord
  include Sanitizable

  has_many :books, dependent: :nullify

  sanitizes :name

  validates :name, presence: true, uniqueness: true
  before_validation :titleize_name

  private

  def titleize_name
    self.name = name.to_s.squish.titleize if name.present? && name_changed?
  end
end
