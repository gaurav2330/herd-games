class Game < ApplicationRecord
  has_many :rooms, dependent: :destroy
end
