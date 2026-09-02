class CreateRealworld < ActiveRecord::Migration[8.1]
  def change
    create_table :users do |t|
      t.string :username, null: false
      t.string :email, null: false
      t.string :password_digest, null: false
      t.text :bio
      t.string :image
      t.timestamps null: false
    end
    add_index :users, :username, unique: true
    add_index :users, :email, unique: true

    create_table :articles do |t|
      t.references :user, null: false, foreign_key: { on_delete: :cascade }
      t.string :slug, null: false
      t.string :title, null: false
      t.text :description, null: false
      t.text :body, null: false
      t.timestamps null: false
    end
    add_index :articles, :slug, unique: true
    add_index :articles, [:user_id, :created_at]

    create_table :tags do |t|
      t.string :name, null: false
    end
    add_index :tags, :name, unique: true

    create_table :article_tags do |t|
      t.references :article, null: false, foreign_key: { on_delete: :cascade }
      t.references :tag, null: false, foreign_key: { on_delete: :cascade }
    end
    add_index :article_tags, [:article_id, :tag_id], unique: true

    create_table :comments do |t|
      t.references :article, null: false, foreign_key: { on_delete: :cascade }
      t.references :user, null: false, foreign_key: { on_delete: :cascade }
      t.text :body, null: false
      t.timestamps null: false
    end

    create_table :favorites do |t|
      t.references :article, null: false, foreign_key: { on_delete: :cascade }
      t.references :user, null: false, foreign_key: { on_delete: :cascade }
    end
    add_index :favorites, [:article_id, :user_id], unique: true

    create_table :follows do |t|
      t.references :follower, null: false, foreign_key: { to_table: :users, on_delete: :cascade }
      t.references :followed, null: false, foreign_key: { to_table: :users, on_delete: :cascade }
    end
    add_index :follows, [:follower_id, :followed_id], unique: true
    add_check_constraint :follows, "follower_id <> followed_id", name: "follows_distinct_users"
  end
end
