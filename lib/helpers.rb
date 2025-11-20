# frozen_string_literal: true

require 'json'
require 'natural_sort'
require 'i18n'
require 'cgi'
require 'nokogiri'

use_helper Nanoc::Helpers::Rendering
use_helper Nanoc::Helpers::LinkTo

def run_magick(*args)
  magick_cmd = 'magick'
  unless system("command -v #{magick_cmd} >/dev/null 2>&1")
    magick_cmd = 'convert' if RUBY_PLATFORM.include?('linux')
  end

  system(magick_cmd, *args)
end

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

def lucide_icon_svg(name, params: {})
  size = params.fetch(:size, 24)
  width = params.fetch(:width, size)
  height = params.fetch(:height, size)
  clazz = params.fetch(:class, '')

  icon = @items["/static/lucide-icons/#{name}.*"]
  raise "Can't find lucide icon '/static/lucide-icons/#{name}.*'" if icon.nil?

  svg_dom = Nokogiri::XML(icon.compiled_content)
  svg_node = svg_dom.root

  svg_node['width'] = width
  svg_node['height'] = height
  svg_node['class'] = [svg_node['class'], clazz].compact.join(' ')

  svg_dom.to_xml(:save_with => Nokogiri::XML::Node::SaveOptions::NO_DECLARATION).chomp
end

def star_svg(filled:, size: 24)
  lucide_icon_svg('star', params: { size: size, class: "star-icon #{filled ? 'icon-active' : 'icon-inactive'}" })
end

def heart_svg(size: 24)
  lucide_icon_svg('heart', params: { size: size, class: 'heart-icon' })
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

def hex_color_to_rgba(hex, opacity: 1.0)
  rgb = hex.match(/^#(..)(..)(..)$/).captures.map(&:hex)
  "rgba(#{rgb.join(", ")}, #{opacity})"
end

def find_book_by_isbn(isbn)
  @items.find { |item| book?(item) && item[:isbn] == isbn }
end

def link_to_book(isbn, title = nil)
  book = find_book_by_isbn(isbn)
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
                .sort_by { |item| [item[:priority], item[:isbn]] }
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
        .sort_by { |item| item[:isbn] }
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
        books: books.sort_by { |book| sortable_label(book[:title]) }
                    .map { |p| p.identifier.to_s },
        extension: 'md'
      }, Nanoc::Identifier.new(tag_item_identifier(tag))
    )
  end
end

def quote_markup(text:, author: nil)
  paragraphs = text.split("\n").map { |line| "<p>#{line}</p>" }.join
  figcaption = author.nil? ? '' : %Q[<figcaption class="quote-author">—&nbsp;#{author}</figcaption>]
  %Q[<figure class="quote"><blockquote class="quote-text">#{paragraphs}</blockquote>#{figcaption}</figure>]
end

def book_description_metadata(book, max_words:)
  Nokogiri::HTML(book.compiled_content).text.split.first(max_words).join(' ') + '…'
end
