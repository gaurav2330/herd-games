class GameChannel < ApplicationCable::Channel
  def subscribed
    room = Room.find(params[:room_id])
    stream_from "game_channel_#{room.id}"
  end

  def unsubscribed
    stop_all_streams
  end

  def draw(data)
    ActionCable.server.broadcast(
      "game_channel_#{data["room_id"]}",
      data
    )
  end
end
