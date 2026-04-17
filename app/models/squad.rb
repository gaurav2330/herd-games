class Squad < ApplicationRecord
  has_many :squad_memberships, dependent: :destroy
  has_many :users, through: :squad_memberships
  has_many :rooms, dependent: :destroy
end
