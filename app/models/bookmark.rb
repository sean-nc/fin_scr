class Bookmark < ApplicationRecord
  belongs_to :search_term
  validates :page_number, presence: true
  validates :search_term_id, presence: true
end
