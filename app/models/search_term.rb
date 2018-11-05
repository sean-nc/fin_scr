class SearchTerm < ApplicationRecord
  has_one :bookmark, dependent: :destroy
  validates :query, presence: true, uniqueness: true
end
