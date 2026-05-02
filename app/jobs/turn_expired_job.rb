class TurnExpiredJob < ApplicationJob
  queue_as :default

  def perform(turn_id)
    turn = Turn.find_by(id: turn_id)
    return unless turn
    return unless turn.status == "drawing"

    room = turn.round.room
    return unless room.status == "active"
    turn.update(status: "completed", ended_at: Time.current)
  
    total_guessers = room.room_memberships.count - 1
    correct_guessers = turn.scores.count
  
    if total_guessers > 0
      drawer_points = (500 * (correct_guessers.to_f / total_guessers)).round
      if drawer_points > 0
        Score.create(
          user: turn.user,
          scoreable: turn,
          points: drawer_points
        )
      end
    end
  
    BroadcastTurnEnded.call(turn, room)
  end
end