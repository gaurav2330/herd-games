class NextRoundJob < ApplicationJob
  queue_as :game_critical

  def perform(room_id)
    room = Room.find_by(id: room_id)
    return unless room&.status == "active"
    return unless room.room_memberships.count >= 2

    round = room.rounds.create(round_number: room.rounds.count + 1)
    first_drawer = room.users_by_join_order.first

    turn = round.create_selecting_turn(drawer_user: first_drawer)
    return unless turn.persisted?

    broadcast_selecting_phase(room, turn)
  end

  private

  def broadcast_selecting_phase(room, turn)
    word_selection_duration = (room.config["word_selection_duration"] || 10).to_i

    Turbo::StreamsChannel.broadcast_replace_to(
      room,
      target: "game-center",
      partial: "rooms/waiting_for_word",
      locals: { turn: turn, room: room }
    )

    Turbo::StreamsChannel.broadcast_replace_to(
      turn.user,
      target: "game-center",
      partial: "rooms/word_selection",
      locals: { turn: turn, room: room }
    )

    Turbo::StreamsChannel.broadcast_replace_to(
      room,
      target: "game-timer",
      html: "<span id='game-timer' data-controller='timer' data-timer-seconds-value='#{word_selection_duration}' class='text-primary font-headline font-black text-3xl leading-none'>#{word_selection_duration}</span>"
    )

    Turbo::StreamsChannel.broadcast_update_to(
      room,
      target: "word-display",
      html: "<span class='font-headline font-bold text-lg text-on-surface-variant animate-pulse'>Selecting word...</span>"
    )

    selecting_chat_html = <<~HTML.squish
      <div id="chat-input" class="p-3 bg-surface-container border-t-4 border-on-surface">
        <div class="w-full p-3 bg-surface border-4 border-outline-variant text-on-surface-variant font-bold text-center text-sm uppercase opacity-60">
          <span class="material-symbols-outlined text-sm align-middle">lock</span>
          Wait for drawing to start
        </div>
      </div>
    HTML

    Turbo::StreamsChannel.broadcast_replace_to(room, target: "chat-input", html: selecting_chat_html)
  end
end