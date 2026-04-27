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

  def chat(data)
    room = Room.find(data["room_id"])
    turn = room.rounds.last.turns.last
    message = data["message"].to_s.strip
    word = turn.word.to_s.downcase
    user = User.find_by(id: data["userId"])

    result = check_guess(message.downcase, word)
    if result == "correct"
      turn_duration = room.config["turn_duration"] || 80
      time_elapsed = Time.current - turn.started_at
      remaining_time = turn_duration - time_elapsed
      points = 500 * (remaining_time / turn_duration)

      Score.create(
        user: user,
        scoreable: turn,
        points: points
      )

      total_guessers = room.room_memberships.count - 1
      correct_guessers = turn.scores.count

      if correct_guessers == total_guessers
        end_turn(turn, room)
      end
    end

    ActionCable.server.broadcast("game_channel_#{room.id}", {
      type: "chat",
      user: user.username,
      user_id: user.id,
      message: message,
      status: result
    })

    broadcast_scoreboard(room, turn)
  end

  private

  def broadcast_scoreboard(room, turn)
    Turbo::StreamsChannel.broadcast_update_to(
      room,
      target: "scoreboard",
      partial: "rooms/scoreboard",
      locals: { room: room, turn: turn }
    )
  end

  def end_turn(turn, room)
    turn.update(status: "updated", ended_at: Time.current)

    total_guessers = room.room_memberships.count - 1
    correct_guessers = turn.scores.count
    drawer_points = (500 * (correct_guessers.to_f / total_guessers)).round

    Score.create(
      user: turn.user,
      scoreable: turn,
      points: drawer_points
    )

    # broadcast turn ended — start next turn
    Turbo::StreamsChannel.broadcast_replace_to(
      room,
      target: "game-center",
      html: "<section class='flex-1 flex flex-col gap-4 overflow-hidden' id='game-center'><div class='flex-1 flex items-center justify-center font-headline font-black text-4xl uppercase'>Next turn starting...</div></section>"
    )
  end

  def check_guess(message, word)
    return "correct" if message == word
    return "close" if levenshtein_distance(message, word) <= 1
    return "wrong"
  end

  def levenshtein_distance(a, b)
    m, n = a.length, b.length
    d = Array.new(m + 1) { Array.new(n + 1, 0) }
    (0..m).each { |i| d[i][0] = i }
    (0..n).each { |j| d[0][j] = j }
    (1..n).each do |j|
      (1..m).each do |i|
        cost = a[i-1] == b[j-1] ? 0 : 1
        d[i][j] = [d[i-1][j] + 1, d[i][j-1] + 1, d[i-1][j-1] + cost].min
      end
    end
    d[m][n]
  end
end
