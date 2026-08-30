module ApplicationHelper
  def page_title
    base = t("site.name")
    content_for(:title).present? ? "#{content_for(:title)} — #{base}" : base
  end

  def nav_links
    items = [
      [ t("nav.home"), root_path, controller_name == "home" ],
      [ t("nav.last_readings"), last_readings_path, controller_name == "last_readings" ],
      [ t("nav.wishlist"), wishlist_path, controller_name == "wishlist" ],
      [ t("nav.tags"), tags_path, controller_name == "tags" ],
      [ t("nav.calendar"), calendar_path(year: Time.current.year), controller_name == "calendar" ],
      [ t("nav.feed"), feed_path(format: :xml), false ]
    ]
    content_tag(:ul, class: "nav-list") do
      safe_join(items.map do |label, path, active|
        content_tag(:li, link_to(label, path, class: ("is-active" if active)))
      end)
    end
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

  def star_rating(review)
    rating = review.rating.to_f
    full = (rating / 2).round.clamp(0, 5)
    content_tag(:span, class: "stars", title: "#{rating.to_i}/10", "aria-label": t("meta.rating_out_of", rating: rating.to_i)) do
      safe_join((1..5).map { |n| content_tag(:span, n <= full ? "★" : "☆", class: "star #{n <= full ? "on" : "off"}", aria_hidden: true) })
    end
  end

  def cover_tag(book, variant: :default)
    if book.cover.attached?
      image_tag(book.cover.variant(variant), alt: book.title, class: "cover", loading: "lazy")
    else
      content_tag(:div, class: "cover cover--placeholder", aria_hidden: true) do
        content_tag(:span, book.title.to_s.first.to_s.upcase)
      end
    end
  end
end
