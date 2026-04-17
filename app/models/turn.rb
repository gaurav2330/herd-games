class Turn < ApplicationRecord
  belongs_to :round
  belongs_to :user
  has_many :scores, as: :scoreable, dependent: :destroy
end
