class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy
  has_many :room_memberships, dependent: :destroy
  has_many :rooms, through: :room_memberships
  has_many :owned_rooms, class_name: "Room", foreign_key: "admin_id"
  has_many :squad_memberships, dependent: :destroy
  has_many :squads, through: :squad_memberships
  has_many :turns, dependent: :destroy
  has_many :scores, dependent: :destroy

  normalizes :email_address, with: ->(e) { e.strip.downcase }
end
