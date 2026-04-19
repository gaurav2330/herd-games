class RoomsController < ApplicationController

  def create
    @room = Room.new(
      game_id: params[:game_id],
      admin: current_user,
      status: "drafted",
      code: SecureRandom.alphanumeric(6).upcase,
      config: default_config
    )
    if @room.save
      @room.room_memberships.create(user: current_user)
      redirect_to @room
    else
      redirect_to game_path(params[:game_id]), alert: "Failed to create room"
    end
  end

  def show
    @room = Room.includes(room_memberships: :user).find(params[:id])
  end

  def update
    @room = Room.find(params[:id])
    @room.update(config: params[:room][:config])
    redirect_to @room
  end

  def join
    @room = Room.find_by(code: params[:code])
    if @room
      RoomMembership.find_or_create_by(room: @room, user: current_user)
      puts "Broadcasting update to players list"
      Turbo::StreamsChannel.broadcast_update_to(
        @room,
        target: "players_list",
        partial: "rooms/players_list",
        locals: { room: @room }
      )
      puts "Update broadcasted"
      redirect_to @room
    else
      redirect_to games_path, alert: "Room not found"
    end
  end

  private

  def default_config
    {
      turn_duration: 80,
      max_players: 10,
      rounds: 8,
      word_options: 3,
      word_selection_duration: 10
    }
  end
end
