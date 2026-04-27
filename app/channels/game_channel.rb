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
    ActionCable.server.broadcast("game_channel_#{room.id}", {
      type: "chat",
      user: user.username,
      user_id: user.id,
      message: message,
      status: result
    })
  end

  private

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
