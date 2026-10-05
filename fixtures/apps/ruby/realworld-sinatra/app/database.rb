# frozen_string_literal: true

require "sequel"

# The SQLite database the launcher clones for each test from the seed built
# into the image. Sequel keeps every timestamp in UTC.
module RealWorld
  # WEBrick uses threads; Sequel checks out a connection per request.
  Sequel.default_timezone = :utc
  DB = Sequel.connect(
    adapter: "sqlite",
    database: ENV.fetch("DATABASE_PATH"),
    timeout: 5000,
    max_connections: 1
  )
  DB.run("PRAGMA foreign_keys = ON")

  SCHEMA = lambda do |db|
    db.create_table?(:users) do
      primary_key :id
      String :username, null: false, unique: true
      String :email, null: false, unique: true
      String :password_digest, null: false
      String :bio, text: true
      String :image
      DateTime :created_at, null: false
      DateTime :updated_at, null: false
    end
    db.create_table?(:articles) do
      primary_key :id
      foreign_key :user_id, :users, null: false, on_delete: :cascade
      String :slug, null: false, unique: true
      String :title, null: false
      String :description, text: true, null: false
      String :body, text: true, null: false
      DateTime :created_at, null: false
      DateTime :updated_at, null: false
      index [:user_id, :created_at]
    end
    db.create_table?(:tags) do
      primary_key :id
      String :name, null: false, unique: true
    end
    db.create_table?(:article_tags) do
      primary_key :id
      foreign_key :article_id, :articles, null: false, on_delete: :cascade
      foreign_key :tag_id, :tags, null: false, on_delete: :cascade
      unique [:article_id, :tag_id]
    end
    db.create_table?(:comments) do
      primary_key :id
      foreign_key :article_id, :articles, null: false, on_delete: :cascade
      foreign_key :user_id, :users, null: false, on_delete: :cascade
      String :body, text: true, null: false
      DateTime :created_at, null: false
      DateTime :updated_at, null: false
    end
    db.create_table?(:favorites) do
      primary_key :id
      foreign_key :article_id, :articles, null: false, on_delete: :cascade
      foreign_key :user_id, :users, null: false, on_delete: :cascade
      unique [:article_id, :user_id]
    end
    db.create_table?(:follows) do
      primary_key :id
      foreign_key :follower_id, :users, null: false, on_delete: :cascade
      foreign_key :followed_id, :users, null: false, on_delete: :cascade
      unique [:follower_id, :followed_id]
      constraint(:follows_distinct_users) { follower_id !~ followed_id }
    end
  end
end
