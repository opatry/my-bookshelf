# frozen_string_literal: true

require 'json'

def to_json(book)
  cover = @items["/cover/#{book[:isbn]}.*"]
  cover_path = cover.path rep: :mini unless cover.nil?
  {
    'title' => book[:title],
    'author' => book[:author],
    'link' => book.path,
    'rating' => book[:rating] || 0,
    'favorite' => book[:favorite] || false,
    'cover' => cover_path || ''
  }
end

def book?(item)
  item.identifier =~ '/book/*'
end

def star_svg(filled:)
  bg_color = filled ? '#FFEA00' : '#D2D2D2'
  fg_color = filled ? '#C1AB60' : '#686868'
  %Q[<svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 512 512" xml:space="preserve" style="padding: 0px 1px;"><polygon fill="#{bg_color}" stroke="#{fg_color}" stroke-width="37.6152" stroke-linecap="round" stroke-linejoin="round" stroke-miterlimit="10" points="259.216,29.942 330.27,173.919 489.16,197.007 374.185,309.08 401.33,467.31 259.216,392.612 117.104,467.31 144.25,309.08 29.274,197.007 188.165,173.919 "></polygon></svg>]
end

def heart_svg
  %Q[<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24"class="heart-icon" ><path d="M12 20a1 1 0 0 1-.437-.1C11.214 19.73 3 15.671 3 9a5 5 0 0 1 8.535-3.536l.465.465.465-.465A5 5 0 0 1 21 9c0 6.646-8.212 10.728-8.562 10.9A1 1 0 0 1 12 20z"></path></svg>]
end

def page_title(item)
  if book?(item)
    "#{item[:title]} par #{item[:author]}"
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
