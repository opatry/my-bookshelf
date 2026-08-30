class CreateBooks < ActiveRecord::Migration[8.0]
  def change
    create_table :books do |t|
      t.string :isbn
      t.string :title
      t.string :author
      t.integer :page_count
      t.integer :publication_year
      t.text :description
      t.string :senscritique_id
      t.string :babelio_id
      t.references :series, null: true, foreign_key: true

      t.timestamps
    end
    add_index :books, :isbn, unique: true
  end
end
