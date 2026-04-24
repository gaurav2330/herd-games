class TurnExpiredJob < ApplicationJob
  queue_as :default

  def perform(turn_id)
    turn = Turn.find_by(id: turn_id)

    return unless turn
    return unless turn.status == "selecting"

    word = turn.word_choices.sample
    turn.update(word: word, status: "drawing")

    room = turn.round.room

    Turbo::StreamsChannel.broadcast_replace_to(
      room,
      target: "game-center",
      partial: "rooms/drawing_phase",
      locals: { turn: turn, is_drawer: false, room: room }
    )
  end
end
