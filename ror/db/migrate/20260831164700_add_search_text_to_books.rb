class AddSearchTextToBooks < ActiveRecord::Migration[8.0]
  def up
    add_column :books, :search_text, :text
    Book.find_each do |book|
      book.update_columns search_text: SearchNormalizer.normalize(search_source(book))
    end
  end

  def down
    remove_column :books, :search_text
  end

  private

  def search_source(book)
    [ book.title, book.author, book.tags.map(&:name) ].flatten.join(" ")
  end
end
