class NextTurnJob < ApplicationJob
  queue_as :game_critical

  def perform(room_id, round_id)
    Rails.logger.info("[NextTurnJob] START room_id=#{room_id} round_id=#{round_id}")

    room = Room.find_by(id: room_id)
    unless room&.status == "active"
      Rails.logger.info("[NextTurnJob] SKIP room not active (status=#{room&.status})")
      return
    end
    unless room.room_memberships.count >= 2
      Rails.logger.info("[NextTurnJob] SKIP fewer than 2 members (count=#{room.room_memberships.count})")
      return
    end

    round = Round.find_by(id: round_id)
    unless round&.room_id == room.id
      Rails.logger.info("[NextTurnJob] SKIP round not found or mismatched")
      return
    end

    last_turn = round.turns.order(:id).last
    unless last_turn&.status == "completed"
      Rails.logger.info("[NextTurnJob] SKIP last turn not completed (status=#{last_turn&.status})")
      return
    end

    drawer = room.next_drawer_after(last_turn.user)
    turn = round.create_selecting_turn(drawer_user: drawer)
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
