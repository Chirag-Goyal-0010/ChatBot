class CreateWebsiteChunks < ActiveRecord::Migration[8.0]
  def change
    create_table :website_chunks do |t|
      t.text :content
      t.string :section
      t.references :website, null: false, foreign_key: true
      t.integer :position

      t.timestamps
    end
  end
end
