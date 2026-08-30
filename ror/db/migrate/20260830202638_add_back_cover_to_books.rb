class AddBackCoverToBooks < ActiveRecord::Migration[8.0]
  def change
    add_column :books, :back_cover, :text
  end
end
