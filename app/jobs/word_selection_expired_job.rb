class WordSelectionExpiredJob < ApplicationJob
  queue_as :default

  def perform(turn_id)
    turn = Turn.find_by(id: turn_id)
    return unless turn
    return unless turn.status == "selecting"

    room = turn.round.room
    return unless room.status == "active"
    word = turn.word_choices.sample
    turn.update(word: word, status: "drawing", started_at: Time.current)

    turn_duration = room.config["turn_duration"] || 80

    Turbo::StreamsChannel.broadcast_replace_to(
      room,
      target: "game-center",
      partial: "rooms/drawing_phase",
      locals: { turn: turn, room: room }
    )

    Turbo::StreamsChannel.broadcast_update_to(
      room,
      target: "word-display",
      html: "<span id='word-blanks' class='font-headline font-black text-2xl tracking-[0.4rem] text-on-surface'>#{turn.word.gsub(/[a-zA-Z]/, '_ ').strip}</span><span id='word-actual' class='font-headline font-black text-2xl tracking-widest uppercase text-primary hidden'>#{turn.word}</span><span class='text-xs font-bold uppercase text-on-surface-variant'>#{turn.word.length} letters</span>"
    )

    Turbo::StreamsChannel.broadcast_update_to(
      turn.user,
      target: "word-display",
      html: "<span id='word-actual' class='font-headline font-black text-2xl tracking-widest uppercase text-primary'>#{turn.word}</span>"
    )

    Turbo::StreamsChannel.broadcast_replace_to(
      room,
      target: "game-timer",
      html: "<span id='game-timer' data-controller='timer' data-timer-seconds-value='#{turn_duration}' class='text-primary font-headline font-black text-3xl leading-none'>#{turn_duration}</span>"
    )

    Turbo::StreamsChannel.broadcast_update_to(
      room,
      target: "drawer-status",
      html: "<span class='font-headline font-bold text-sm text-on-surface'>#{turn.user.username} is drawing...</span>"
    )

    Turbo::StreamsChannel.broadcast_update_to(
      room,
      target: "chat-input",
      partial: "rooms/chat_input",
      locals: { is_drawer: false }
    )

    Turbo::StreamsChannel.broadcast_update_to(
      turn.user,
      target: "chat-input",
      partial: "rooms/chat_input",
      locals: { is_drawer: true }
    )

    # enqueue drawing timer
    TurnExpiredJob.set(wait: turn_duration.seconds).perform_later(turn.id)
  end
end