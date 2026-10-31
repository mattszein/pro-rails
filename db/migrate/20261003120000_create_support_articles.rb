class CreateSupportArticles < ActiveRecord::Migration[8.1]
  def change
    create_table :support_articles do |t|
      t.string :title, null: false
      t.string :slug, null: false
      t.text :summary, null: false
      t.integer :category
      t.string :locale, null: false, default: "en"
      t.integer :status, null: false, default: 0
      t.datetime :published_at
      t.references :author, foreign_key: {to_table: :accounts, on_delete: :nullify}
      t.text :search_text

      t.virtual :searchable, type: :tsvector, stored: true, as: <<~SQL.squish
        setweight(to_tsvector('simple', coalesce(title, '')), 'A') ||
        setweight(to_tsvector('simple', coalesce(summary, '')), 'B') ||
        setweight(to_tsvector('simple', coalesce(search_text, '')), 'C')
      SQL

      t.timestamps
    end

    add_index :support_articles, :searchable, using: :gin
    add_index :support_articles, [:locale, :slug], unique: true
    add_index :support_articles, [:status, :locale]
  end
end
