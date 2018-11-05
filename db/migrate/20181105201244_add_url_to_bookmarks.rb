class AddUrlToBookmarks < ActiveRecord::Migration[5.2]
  def change
    add_column :bookmarks, :url, :string
  end
end
