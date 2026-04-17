class RoomMembership < ApplicationRecord
  belongs_to :room
  belongs_to :user
end
