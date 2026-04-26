class AddUniqueIndexToRoomMemberships < ActiveRecord::Migration[8.1]
  def change
    add_index :room_memberships, [:room_id, :user_id], unique: true
  end
end
