# frozen_string_literal: true

require 'json'
require 'natural_sort'
require 'i18n'
require 'cgi'

use_helper Nanoc::Helpers::Rendering
use_helper Nanoc::Helpers::LinkTo

def h(text)
  CGI.escapeHTML(text.nil? ? '' : text)
end

def to_json(book, url: :relative)
  cover = @items["/cover/#{book[:isbn]}.*"]
  cover_path = cover.path(rep: :default) unless cover.nil?
  cover_mini_path = cover.path(rep: :mini) unless cover.nil?
  url_prefix = url == :absolute ? @config[:site][:url] : ''
  read_date = book[:read_date].iso8601 if book[:read_date].is_a?(Date)
  {
    'isbn': book[:isbn],
    'uuid': book[:uuid],
    'title': book[:title],
    'author': book[:author],
    'link': "#{url_prefix}#{book.path}",
    'rating': book[:rating] || 0,
    'read_date': read_date,
    'priority': book[:priority],
    'ongoing': book[:ongoing] || false,
    'favorite': book[:favorite] || false,
    'cover': "#{url_prefix}#{cover_path}" || '',
    'cover_mini': "#{url_prefix}#{cover_mini_path}" || '',
    'tags': book[:tags] || [],
  }
end

def home?(item)
  item.identifier =~ '/index.*'
end

def book?(item)
  item.identifier =~ '/book/*'
end

def star_svg(filled:, params: {})
  size = params.fetch(:size, 24)
  width = params.fetch(:width, size)
  height = params.fetch(:height, size)
  %Q[<svg xmlns="http://www.w3.org/2000/svg" xml:space="preserve" width="#{width}" height="#{height}" viewBox="0 0 576 512" class="star-icon #{filled ? 'icon-active' : 'icon-inactive'}"><!--!Font Awesome Free 6.5.2 by @fontawesome - https://fontawesome.com License - https://fontawesome.com/license/free Copyright 2024 Fonticons, Inc.--><path d="M316.9 18C311.6 7 300.4 0 288.1 0s-23.4 7-28.8 18L195 150.3 51.4 171.5c-12 1.8-22 10.2-25.7 21.7s-.7 24.2 7.9 32.7L137.8 329 113.2 474.7c-2 12 3 24.2 12.9 31.3s23 8 33.8 2.3l128.3-68.5 128.3 68.5c10.8 5.7 23.9 4.9 33.8-2.3s14.9-19.3 12.9-31.3L438.5 329 542.7 225.9c8.6-8.5 11.7-21.2 7.9-32.7s-13.7-19.9-25.7-21.7L381.2 150.3 316.9 18z"/></svg>]
end

def heart_svg(params: {})
size = params.fetch(:size, 24)
  width = params.fetch(:width, size)
  height = params.fetch(:height, size)
  %Q[<svg xmlns="http://www.w3.org/2000/svg" xml:space="preserve" width="#{width}" height="#{height}" viewBox="0 0 24 24" class="heart-icon"><path d="M12 20a1 1 0 0 1-.437-.1C11.214 19.73 3 15.671 3 9a5 5 0 0 1 8.535-3.536l.465.465.465-.465A5 5 0 0 1 21 9c0 6.646-8.212 10.728-8.562 10.9A1 1 0 0 1 12 20z"/></svg>]
end

def join_with_prefix(array, separator: ' ', prefix: '')
  str = array.compact.join(separator)
  str.empty? ? '' : "#{prefix}#{str}"
end

def page_title(item)
  if book?(item)
    rating = "⭐️ #{@item[:rating]}/10" unless item[:rating].nil? || item[:rating].zero?
    favorite = "❤️" if @item[:favorite]
    "#{item[:title]} par #{item[:author]} #{join_with_prefix([rating, favorite], prefix: ' • ')}"
  else
    item[:title]
  end
end

def format_isbn(isbn)
  # xxx-x-xx-xxxxxx-x
  # FIXME not fully relevant depending on the country issuing the book
  # https://en.wikipedia.org/wiki/ISBN
  # r = /^(\d{3})(\d{1})(\d{2})(\d{6})(\d{1})$/
  # isbn.split(r).reject(&:empty?).join('-')

  # xxx-xxxxxxxxxx
  isbn.dup.insert(3, '-')
end

def linked_book_title(item, linked_book:)
  # try to find a common prefix before the word "tome" and trim it
  item_title_prefix = item[:title].split("tome").first
  linked_book_title_prefix = linked_book[:title].split("tome").first
  if (item_title_prefix == linked_book_title_prefix)
    linked_book[:title].sub(linked_book_title_prefix, '')
  else
    linked_book[:title]
  end
end

def hex_color_to_rgba(hex, opacity)
  rgb = hex.match(/^#(..)(..)(..)$/).captures.map(&:hex)
  "rgba(#{rgb.join(", ")}, #{opacity})"
end

def link_to_book(isbn, title = nil)
  book = @items["/book/#{isbn}.*"]
  if book.nil?
    raise "Can't find book #{isbn} and no fallback title provided" if title.nil?
    puts "Warning: link_to_book(#{isbn}, #{title}), can't resolve book"
    title
  else
    link_label = title.nil? ? book[:title] : title
    puts "Warning: link_to_book(#{isbn}, #{title}), book title differs #{title} vs #{book[:title]}" if !title.nil? && title != book[:title]
    %Q[[#{link_label}](#{book.path})]
  end
end

def sortable_label(label)
  NaturalSort(I18n.transliterate(label.downcase).gsub(/\W/, ' ').gsub(/\s+/, ' ').strip)
end

def natural_sort(books)
  books.sort_by { |book| sortable_label(book[:title]) }
end

def pwa_screenshot_to_json(item)
  {
    'src': item.path,
    'sizes': "#{item[:width]}x#{item[:height]}",
    'type': item[:mime_type],
    'platform': item[:pwa_platform],
    'form_factor': item[:pwa_form_factor],
  }
end

def get_pretty_date(book)
  read_date = book[:read_date]
  return nil unless read_date.is_a?(Date)

  read_date_output = "#{I18n.t('date.month_names')[read_date.month]} #{read_date.year}"
  %Q[<time datetime="#{read_date.strftime('%Y-%m-%d')}">#{read_date_output}</time>]
end

def get_atom_date(book)
  # 2015-01-24T14:52:47Z
  book[:read_date].strftime('%Y-%m-%dT%H:%M:%SZ')
end

def ongoing_book_info()
  ongoing_books = @items.select { |book| book.identifier =~ '/book/*' && book[:ongoing] }
  raise 'Only one book can be ongoing' if ongoing_books.length > 1
  ongoing_book = ongoing_books.first
  ongoing_book_cover = @items["/cover/#{ongoing_book[:isbn]}.*"] unless ongoing_book.nil?
  [ongoing_book, ongoing_book_cover]
end

# Returns the last books sorted by read date in descending order.
#
# @param limit [Integer, nil] the maximum number of books to return. If nil, returns all books.
# @return [Array<Hash>] an array of book items sorted by read date.
def last_books(limit = nil)
  books = @items.select { |item| book?(item) && item[:read_date].is_a?(Date) }
                .sort_by { |item| -item[:read_date].to_time.to_i }
  limit.nil? ? books : books.first(limit)
end

# Returns the wished books sorted by priority in ascending order.
#
# @param limit [Integer, nil] the maximum number of books to return. If nil, returns all books.
# @return [Array<Hash>] an array of book items sorted by priority.
def wished_books(limit = nil)
  books = @items.select { |item| book?(item) && !item[:priority].nil? }
                .sort_by { |item| item[:priority] }
  limit.nil? ? books : books.first(limit)
end

def recent_books()
  six_months_ago = Date.today << 60
  last_books(6).select { |book| book[:read_date] >= six_months_ago }
end

def feed_books()
  last_books(@config[:site][:feed][:max_entries])
end

def rated_books()
  @items.select { |item| book?(item) && !item[:rating].nil? && !item[:rating].zero? }
end

def all_tags
  tags = {}
  @items.each do |item|
    next if item[:tags].nil? || item[:tags].empty?

    item[:tags].each do |tag|
      tags[tag] = [] if tags[tag].nil?
      tags[tag] << item unless tags[tag].include? item
    end
  end
  tags
end

def tag_cloud
  # sort on hash sort by key which is what we want
  tags = all_tags.sort
  result = []
  return result if tags.empty?
  # tag_<weight> goes from tag_0 to tag_10, map tag weight value to [0,10]
  max = tags.max_by { |_, v| v.size }[1].size
  min = tags.min_by { |_, v| v.size }[1].size
  tags.each do |tag, posts|
    posts_count = posts.size
    tag_weight = (((posts_count - min) * 10.0) / max).round
    result << [tag, tag_weight, posts_count]
  end
  result
end

def tag_slug(tag)
  I18n.transliterate(tag.downcase).gsub(/\W/, '-').gsub(/-+/, '-').strip
end

def tag_item_identifier(tag)
  "/tag/#{tag_slug(tag)}.*"
end

def link_to_tag(tag)
  tag_item = @items[tag_item_identifier(tag)]
  link_to(tag_item[:title], tag_item)
end

def generate_tag_items
  all_tags.each do |tag, books|
    # item's content is used as fallback when no post can be found.
    @items.create("
Aucun livre n'est étiqueté \"<%= @item[:title] %>\".

Voir la liste des <%= link_to('autres étiquettes', @items['/all-tags.*']) %>.
      ", {
        title: tag,
        tag: tag_slug(tag),
        layout: 'tags',
        # can't store item ref, from the preprocess block, the item view isn't suitable for future use
        # such as compiled_content, path, reps and so on.
        # only store identifier and request item from identifier at call site
        books: natural_sort(books).map { |p| p.identifier.to_s },
        extension: 'md'
      }, Nanoc::Identifier.new(tag_item_identifier(tag))
    )
  end
end