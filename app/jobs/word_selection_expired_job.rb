class WordSelectionExpiredJob < ApplicationJob
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

    Turbo::StreamsChannel.broadcast_update_to(
      @room,
      target: "chat-input",
      partial: "rooms/chat_input",
      locals: { is_drawer: false }
    )

    # personal stream for drawer
    Turbo::StreamsChannel.broadcast_update_to(
      @current_turn.user,
      target: "chat-input",
      partial: "rooms/chat_input",
      locals: { is_drawer: true }
    )
  end
end
