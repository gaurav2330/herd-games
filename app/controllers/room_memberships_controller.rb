class RoomMembershipsController < ApplicationController

  def create
    @room = Room.find(params[:room_id])
    return redirect_to @room, alert: "Room is not active" unless @room.status == "drafted"
  
    membership = @room.room_memberships.find_or_create_by(user: current_user)

    Turbo::StreamsChannel.broadcast_update_to(
      @room,
      target: 'players_list',
      partial: 'rooms/players_list',
      locals: { room: @room }
    )
    redirect_to @room
  end
end
