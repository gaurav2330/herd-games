class Round < ApplicationRecord
  belongs_to :room
  has_many :turns, dependent: :destroy
  has_many :scores, as: :scoreable, dependent: :destroy
end
