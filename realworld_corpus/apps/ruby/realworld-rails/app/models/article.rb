class Article < ApplicationRecord
  belongs_to :user
  has_many :article_tags, dependent: :destroy
  has_many :tags, through: :article_tags
  has_many :comments, dependent: :destroy
  has_many :favorites, dependent: :destroy

  validates :slug, presence: true, uniqueness: true
  validates :title, :description, :body, presence: true

  def self.unique_slug(title)
    base = title.to_s.parameterize.presence || "article"
    candidate = base
    candidate = "#{base}-#{SecureRandom.hex(4)}" if exists?(slug: candidate)
    candidate
  end

  def replace_tags!(names)
    raise ArgumentError, "tagList must be an array" unless names.is_a?(Array)
    normalized = names.map { |name| name.to_s.strip }.reject(&:blank?).uniq
    self.tags = normalized.map do |name|
      Tag.find_or_create_by!(name: name)
    rescue ActiveRecord::RecordNotUnique
      Tag.find_by!(name: name)
    end
  end
end
