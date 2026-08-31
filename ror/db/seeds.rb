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

# --- Realistic sample data for visual testing ---------------------------------
# Books are shared (unique ISBN), reviews are per-user. Everything is
# idempotent: re-running seeds never duplicates a book or a review.

def isbn13(number)
  digits = number.to_s.rjust(12, "0").chars.map(&:to_i)
  checksum = digits.each_with_index.sum { |d, i| i.even? ? d : d * 3 }
  (digits + [ (10 - (checksum % 10)) % 10 ]).join
end

# Demo covers are borrowed from the static site (repo root `content/cover/`) so
# the seeded books display real covers. Any cover works — the demo books don't
# have matching artworks, so they are picked deterministically (round-robin).
COVER_DIR = File.expand_path("../../content/cover", __dir__)
COVERS = Dir[File.join(COVER_DIR, "*.jpg")].sort

READ_BOOKS = [
  {
    base: 978236793001, title: "La Horde du Contrevent", author: "Alain Damasio",
    page_count: 720, publication_year: 2004,
    description: "Une expédition bravant les vents des confins, portée par une écriture incandescente.",
    tags: %w[Fantasy Sci-fi], rating: 9, read_date: Date.new(2026, 8, 10), favorite: true
  },
  {
    base: 978207036002, title: "Le Meilleur des mondes", author: "Aldous Huxley",
    page_count: 304, publication_year: 1932,
    description: "Une dystopie fondatrice sur une société de divertissement et de conditionnement.",
    tags: %w[Sci-fi], rating: 7, read_date: Date.new(2026, 7, 22)
  },
  {
    base: 978207036003, title: "L’Étranger", author: "Albert Camus",
    page_count: 192, publication_year: 1942,
    description: "Le récit de Meursault, entre indifférence et absurdité.",
    tags: %w[Psychologie Roman], rating: 8, read_date: Date.new(2026, 6, 5)
  },
  {
    base: 978222631004, title: "Homo Deus", author: "Yuval Noah Harari",
    page_count: 496, publication_year: 2015,
    description: "Une histoire de demain, où l’humanité repousse les limites de la mort et du bonheur.",
    tags: %w[Essai Histoire], rating: 8, read_date: Date.new(2026, 5, 18)
  },
  {
    base: 978225312005, title: "Mille soleils splendides", author: "Khaled Hosseini",
    page_count: 480, publication_year: 2007,
    description: "Deux femmes afghanes unies par l’amour et la guerre.",
    tags: %w[Guerre Amour], rating: 9, read_date: Date.new(2026, 4, 30)
  },
  {
    base: 978207037006, title: "Le Grand Meaulnes", author: "Alain-Fournier",
    page_count: 288, publication_year: 1913,
    description: "Dans la Sologne berrichonne, le souvenir d’une fête mystérieuse.",
    tags: %w[Famille Bretagne], rating: 8, read_date: Date.new(2026, 4, 2)
  },
  {
    base: 978207036007, title: "La Délicatesse", author: "David Foenkinos",
    page_count: 224, publication_year: 2009,
    description: "Le chagrin et la renaissance d’une jeune femme, avec une pointe d’humour.",
    tags: %w[Humour Amour], rating: 7, read_date: Date.new(2026, 3, 15)
  }
]

WISHLIST_BOOKS = [
  {
    base: 978222121001, title: "Dune", author: "Frank Herbert",
    page_count: 704, publication_year: 1965,
    description: "Sur la planète désertique d’Arrakis, les intrigues de trois grandes maisons.",
    tags: %w[Sci-fi], priority: 1
  },
  {
    base: 978207045002, title: "Cent ans de solitude", author: "Gabriel García Márquez",
    page_count: 472, publication_year: 1967,
    description: "Le destin de la famille Buendía à travers le réalisme magique.",
    tags: %w[Famille], priority: 2
  },
  {
    base: 978275780003, title: "2666", author: "Roberto Bolaño",
    page_count: 1120, publication_year: 2004,
    description: "Un roman total sur la violence et les mystères de la frontière mexicaine.",
    tags: %w[Policier], priority: 3
  },
  {
    base: 978229031004, title: "Fondation", author: "Isaac Asimov",
    page_count: 288, publication_year: 1951,
    description: "Hari Seldon fonde une colonie pour préserver le savoir d’un empire en déclin.",
    tags: %w[Sci-fi], priority: 1
  },
  {
    base: 978225300005, title: "Les Misérables", author: "Victor Hugo",
    page_count: 640, publication_year: 1862,
    description: "Jean Valjean, Cosette et Gavroche au cœur du Paris du XIXᵉ siècle.",
    tags: %w[Histoire], priority: 2
  },
  {
    base: 978226402006, title: "Tokyo Express", author: "Seichō Matsumoto",
    page_count: 288, publication_year: 1958,
    description: "Un détail apparemment anodin mène à la vérité dans un train de nuit japonais.",
    tags: %w[Policier Japon], priority: 4
  }
]

def seed_books(entries, user, status)
  entries.each_with_index do |entry, index|
    book = Book.find_or_create_by!(isbn: isbn13(entry[:base])) do |b|
      b.title = entry[:title]
      b.author = entry[:author]
      b.page_count = entry[:page_count]
      b.publication_year = entry[:publication_year]
      b.description = entry[:description]
      b.tags = entry[:tags].map { |name| Tag.find_or_create_by!(name: name) }
    end

    attach_cover(book, COVERS[index % COVERS.size]) if COVERS.any?

    attrs = { user: user, book: book, status: status }
    attrs[:rating] = entry[:rating] if status == :read
    attrs[:read_date] = entry[:read_date] if status == :read
    attrs[:priority] = entry[:priority] if status == :wishlist
    attrs[:favorite] = entry[:favorite] if entry.key?(:favorite)

    Review.find_or_create_by!(user: user, book: book) { |r| r.assign_attributes(attrs) }
  end
end

def attach_cover(book, path)
  return if book.cover.attached?

  book.cover.attach(
    io: File.open(path),
    filename: File.basename(path),
    content_type: "image/jpeg"
  )
end

seed_books(READ_BOOKS, user, :read)
seed_books(WISHLIST_BOOKS, user, :wishlist)

puts "Seeded #{READ_BOOKS.size} read books and #{WISHLIST_BOOKS.size} wishlist books."
