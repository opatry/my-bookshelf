atom_feed do |feed|
  feed.title(t("feed.title", site: t("site.name")))
  feed.subtitle(t("feed.subtitle"))
  feed.updated((@updated_at || Time.current).to_time)

  @reviews.each do |review|
    feed.entry(review,
               id: book_url(review.book),
               url: book_url(review.book),
               published: review.read_date.to_time,
               updated: review.read_date.to_time) do |entry|
      entry.title(t("feed.entry_title", title: review.book.title, author: review.book.author))
      entry.summary(review.book.description) if review.book.description.present?
      entry.author { |author| author.name(t("site.name")) }
    end
  end
end
