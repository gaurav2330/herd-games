class Room < ApplicationRecord
  belongs_to :game
  belongs_to :squad, optional: true
  belongs_to :admin, class_name: "User", foreign_key: "admin_id"
  has_many :room_memberships, dependent: :destroy
  has_many :users, through: :room_memberships
  has_many :rounds, dependent: :destroy
end
