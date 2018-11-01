class CreateProfiles < ActiveRecord::Migration[5.2]
  def change
    create_table :profiles do |t|
      t.string :email
      t.string :title

      t.timestamps
    end
    add_index :profiles, :email, :unique => true
  end
end
