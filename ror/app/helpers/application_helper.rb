module ApplicationHelper
  def page_title
    base = t("site.name")
    content_for(:title).present? ? "#{content_for(:title)} — #{base}" : base
  end

  def read_date_label(review)
    return t("meta.ongoing") unless review.read_date

    t("meta.read_on", date: l(review.read_date, format: :long))
  end

  def page_count_label(book)
    return t("meta.no_page_count") unless book.page_count

    t("meta.pages", count: book.page_count)
  end

  def published_label(book)
    return "" unless book.publication_year

    t("meta.published", year: book.publication_year)
  end

  def star_icon(filled:, size: 16, **)
    %(<svg xmlns="http://www.w3.org/2000/svg" width="#{size}" height="#{size}" viewBox="0 0 24 24"
      class="star-icon #{filled ? "icon-active" : "icon-inactive"}" aria-hidden="true"><path d="M11.525 2.295a.53.53 0 0 1 .95 0l2.31 4.679a2.123 2.123 0 0 0 1.595 1.16l5.166.756a.53.53 0 0 1 .294.904l-3.736 3.638a2.123 2.123 0 0 0-.611 1.878l.882 5.14a.53.53 0 0 1-.771.56l-4.618-2.428a2.122 2.122 0 0 0-1.973 0L6.396 21.01a.53.53 0 0 1-.77-.56l.881-5.139a2.122 2.122 0 0 0-.611-1.879L2.16 9.795a.53.53 0 0 1 .294-.906l5.165-.755a2.122 2.122 0 0 0 1.597-1.16z"/></svg>).html_safe
  end

  def heart_icon(size: 16)
    %(<svg xmlns="http://www.w3.org/2000/svg" width="#{size}" height="#{size}" viewBox="0 0 24 24"
      class="heart-icon" aria-hidden="true"><path d="M2 9.5a5.5 5.5 0 0 1 9.591-3.676.56.56 0 0 0 .818 0A5.49 5.49 0 0 1 22 9.5c0 2.29-1.5 4-3 5.5l-5.492 5.313a2 2 0 0 1-3 .019L5 15c-1.5-1.5-3-3.2-3-5.5"/></svg>).html_safe
  end

  def search_icon(size: 16)
    %(<svg xmlns="http://www.w3.org/2000/svg" width="#{size}" height="#{size}" viewBox="0 0 24 24"
      fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"
      class="input-icon" aria-hidden="true"><path d="m21 21-4.3-4.3"/><circle cx="11" cy="11" r="8"/></svg>).html_safe
  end

  # 10-star rating bar, faithful to the original site's /10 scale.
  def star_rating(review, size: 12)
    rating = review.rating.to_i
    content_tag(:div, class: "rating-bar", "aria-label": t("meta.rating_out_of", rating: rating),
                 title: t("meta.rating_out_of", rating: rating), "data-rating": rating) do
      safe_join((1..10).map { |i| star_icon(filled: i <= rating, size: size) })
    end
  end

  def pretty_read_date(date)
    content_tag(:time, datetime: date.strftime("%Y-%m-%d")) { l(date, format: "%B %Y") }
  end

  def tag_weight(count, max_count)
    return 0 if max_count.zero?

    ((count.to_f / max_count) * 10).round.clamp(0, 10)
  end

  # Metadata sentence for the book page: "1 248 pages, paru en 1844, lu en novembre 2026".
  def book_metadata(book, review)
    metadata = []
    metadata << page_count_label(book) if book.page_count
    metadata << published_label(book) if book.publication_year
    return metadata unless review

    case review.status
    when "read" then metadata << t("meta.read_on_month", date: pretty_read_date(review.read_date))
    when "ongoing" then metadata << t("meta.ongoing_card")
    when "wishlist" then metadata << "#{t("meta.priority_label")} #{review.priority}"
    end
    metadata
  end

  def cover_tag(book, variant: :default, **options)
    if book.cover.attached?
      image_tag(book.cover.variant(variant), alt: book.title, class: "cover #{options.delete(:class)}".strip, loading: options.delete(:loading) || "lazy")
    else
      content_tag(:div, class: "cover cover--placeholder #{options.delete(:class)}".strip, aria_hidden: true) do
        content_tag(:span, book.title.to_s.first.to_s.upcase)
      end
    end
  end
end
