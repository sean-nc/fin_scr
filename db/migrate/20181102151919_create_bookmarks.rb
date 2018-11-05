class CreateBookmarks < ActiveRecord::Migration[5.2]
  def change
    create_table :bookmarks do |t|
      t.references :search_term, foreign_key: true
      t.integer :page_number

      t.timestamps
    end
  end
end
