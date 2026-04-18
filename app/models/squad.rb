class Squad < ApplicationRecord
  has_many :squad_memberships, dependent: :destroy
  has_many :users, through: :squad_memberships
  has_many :rooms, dependent: :destroy
  belongs_to :admin, class_name: "User", foreign_key: "admin_id"
end
