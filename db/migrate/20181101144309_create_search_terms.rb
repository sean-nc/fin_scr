class CreateSearchTerms < ActiveRecord::Migration[5.2]
  def change
    create_table :search_terms do |t|
      t.text :query
      t.boolean :searched, default: false

      t.timestamps
    end
    add_index :search_terms, :query, :unique => true
  end
end
