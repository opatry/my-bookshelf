# Phase 1 has no authentication and acts on a single default user to which
# reviews are attached. Phase 2 introduces per-user accounts.
#
# This seed is idempotent. The password is irrelevant until auth lands in
# Phase 2, but `has_secure_password` requires one.
default_email = ENV.fetch("DEFAULT_USER_EMAIL", "olivier@example.org")
default_password = ENV.fetch("DEFAULT_USER_PASSWORD", "change-me")

user = User.find_or_create_by!(email: default_email) do |u|
  u.name = "Olivier"
  u.password = default_password
  u.password_confirmation = default_password
end

puts "Seeded default user: #{default_email}"

# --- Realistic sample data for visual testing -------------------------------
# Books are real titles from the static site (`repo/content/book/*.md`). Every
# ISBN has a matching cover in `repo/content/cover/{isbn}.jpg`, so the seeded
# books display their actual covers. Everything is idempotent: re-running seeds
# never duplicates a book or a review.

require "yaml"

BOOK_DIR = File.expand_path("../../content/book", __dir__)
COVER_DIR = File.expand_path("../../content/cover", __dir__)

# Reads a static book file and returns a hash of its bibliographic fields.
def load_static_book(filename)
  raw = File.read(File.join(BOOK_DIR, filename))
  frontmatter, description = raw.split(/^---\s*$/, 3).values_at(1, 2)

  data = YAML.safe_load(frontmatter, permitted_classes: [ Date ])
  data["description"] = description.to_s.strip
  data["tags"] ||= []
  data.transform_keys(&:to_sym)
rescue StandardError => e
  abort "Could not parse #{filename}: #{e.message}"
end

def cover_path(isbn)
  File.join(COVER_DIR, "#{isbn}.jpg")
end

def attach_cover(book, isbn)
  return if book.cover.attached?

  path = cover_path(isbn)
  abort "Missing cover for #{isbn} (#{path})" unless File.exist?(path)

  book.cover.attach(
    io: File.open(path),
    filename: "#{isbn}.jpg",
    content_type: "image/jpeg"
  )
end

# entry: static fields + `status` (:read / :ongoing / :wishlist) +
#        optional `overrides` { rating:, read_date:, priority: }.
def seed_book(entry, user)
  status = entry[:status]
  overrides = entry[:overrides].to_h

  book = Book.find_or_initialize_by(isbn: entry[:isbn])
  book.title = entry[:title]
  book.author = entry[:author]
  book.page_count = entry[:page_count]
  book.publication_year = entry[:publication_year]
  book.description = entry[:description]
  book.tags = entry[:tags].map { |name| Tag.find_or_create_by!(name: name) }

  attach_cover(book, entry[:isbn])
  book.save! if book.new_record? || book.changed? || !book.cover.attached?

  attrs = { user: user, book: book, status: status }
  attrs[:rating] = overrides.fetch(:rating, entry[:rating]) if status == :read
  attrs[:read_date] = overrides.fetch(:read_date, entry[:read_date]) if status == :read
  attrs[:priority] = overrides.fetch(:priority, entry[:priority]) if status == :wishlist
  favorite = overrides.key?(:favorite) ? overrides[:favorite] : entry[:favorite]
  attrs[:favorite] = favorite unless favorite.nil?

  Review.find_or_create_by!(user: user, book: book) { |r| r.assign_attributes(attrs) }
end

BOOKS = [
  # --- Read (real covers, real read dates) ---------------------------------
  { file: "arturo-perez-reverte_le-tableau-du-maitre-flamand.md", status: :read },
  { file: "gunnar-staalesen_la-nuit-tous-les-loups-sont-gris.md", status: :read },
  { file: "charlotte-mcconaghy_je-pleure-encore-la-beaute-du-monde.md", status: :read },
  { file: "chris-whitaker_toutes-les-nuances-de-la-nuit.md", status: :read },
  { file: "antoine-laurain_les-caprices-dun-astre.md", status: :read },
  { file: "dan-gemeinhart_lincroyable-voyage-de-coyote-sunrise.md", status: :read },
  { file: "agatha-christie_le-crime-de-lorient-express.md", status: :read },

  # --- Ongoing --------------------------------------------------------------
  # Le Petit Prince is stored as read on the static site; seed it as ongoing so
  # the app's "currently reading" rail is populated.
  { file: "antoine-de-saint-exupery_le-petit-prince.md", status: :ongoing },

  # --- Wishlist --------------------------------------------------------------
  { file: "cathy-kelly_le-meilleur-de-la-vie.md", status: :wishlist },
  { file: "andy-weir_projet-derniere-chance.md", status: :wishlist },
  { file: "catherine-poulain_le-grand-marin.md", status: :wishlist },
  { file: "anthony-doerr_la-cite-des-nuages-et-des-oiseaux.md", status: :wishlist },
  { file: "guy-gavriel-kay_comme-un-diamant-dans-ma-memoire.md", status: :wishlist }
]

read_count = wishlist_count = ongoing_count = 0

BOOKS.each do |config|
  entry = load_static_book(config[:file]).merge(status: config[:status])
  seed_book(entry, user)

  case config[:status]
  when :read then read_count += 1
  when :wishlist then wishlist_count += 1
  when :ongoing then ongoing_count += 1
  end
end

puts "Seeded #{read_count} read, #{ongoing_count} ongoing and #{wishlist_count} wishlist books."
