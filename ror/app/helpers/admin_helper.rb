module AdminHelper
  def review_status_badge(book)
    review = owner&.reviews&.find_by(book: book)
    return nil unless review

    t("admin.review.status_#{review.status}")
  end

  def review_status_options
    Review.statuses.keys.map { |status| [ t("admin.review.status_#{status}"), status ] }
  end
end
