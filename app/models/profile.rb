class Profile < ApplicationRecord
  validates :email, presence: true, uniqueness: true

  def self.search(term)
    if term
      self.where('email ILIKE ?', "%#{term}%").or(self.where('title ILIKE ?', "%#{term}%"))
    else
      self.all
    end
  end
end
