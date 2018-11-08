class SearchTerm < ApplicationRecord
  require 'roo'

  has_one :bookmark, dependent: :destroy
  validates :query, presence: true, uniqueness: true

  def self.import(file)
    spreadsheet = Roo::Spreadsheet.open(file.path)
    (spreadsheet.first_row..spreadsheet.last_row).each do |i|
      term = spreadsheet.row(i)
      SearchTerm.create(query: term[0])
    end
  end
end
