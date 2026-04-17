class Room < ApplicationRecord
  belongs_to :game
  belongs_to :squad
  belongs_to :admin
end
