class SearchTerm < ApplicationRecord
  validates :query, presence: true, uniqueness: true
end
