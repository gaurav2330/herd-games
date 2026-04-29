class Room < ApplicationRecord
  belongs_to :game
  belongs_to :squad, optional: true
  belongs_to :admin, class_name: "User", foreign_key: "admin_id"
  has_many :room_memberships, dependent: :destroy
  has_many :users, through: :room_memberships
  has_many :rounds, dependent: :destroy

  def users_by_join_order
    room_memberships.includes(:user).order(created_at: :asc, id: :asc).map(&:user)
  end

  def next_drawer_after(previous_user)
    ordered_users = users_by_join_order
    return ordered_users.first if previous_user.blank? || ordered_users.empty?

    idx = ordered_users.index(previous_user)
    return ordered_users.first if idx.nil?

    ordered_users[(idx + 1) % ordered_users.size]
  end
end
