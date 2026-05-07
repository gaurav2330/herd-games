class BroadcastTurnEnded
  def self.call(turn, room)
    scores = turn.scores.reload

    scores_html = room.room_memberships.includes(:user).map do |membership|
      user_score = scores.select { |s| s.user_id == membership.user_id }.sum(&:points)
      is_drawer = membership.user_id == turn.user_id

      "<div class='flex items-center justify-between p-4 bg-surface-container-lowest border-4 border-on-surface shadow-[4px_4px_0px_0px_#2d2f2f]'>
        <div class='flex items-center gap-4'>
          <div class='w-12 h-12 bg-primary-container border-4 border-on-surface flex items-center justify-center font-headline font-black text-xl'>
            #{membership.user.username.first.upcase}
          </div>
          <div class='flex flex-col'>
            <span class='font-headline font-bold text-lg uppercase'>#{membership.user.username}</span>
            #{is_drawer ? "<span class='text-xs font-bold uppercase text-on-surface-variant'>Drawer</span>" : ""}
          </div>
        </div>
        <span class='font-headline font-black text-3xl #{user_score > 0 ? "text-primary" : "text-on-surface-variant"}'>
          #{user_score > 0 ? "+#{user_score}" : "+0"}
        </span>
      </div>"
    end.join

    game_center_html = "
      <section class='flex-1 flex flex-col items-center justify-center gap-8 p-8' id='game-center'>
        <div class='text-center'>
          <p class='font-headline font-bold text-sm uppercase tracking-widest text-on-surface-variant mb-2'>The word was</p>
          <h2 class='font-headline font-black text-6xl uppercase text-primary tracking-widest'>#{turn.word}</h2>
        </div>
        <div class='w-full max-w-lg flex flex-col gap-3'>
          #{scores_html}
        </div>
      </section>
    "

    Turbo::StreamsChannel.broadcast_replace_to(
      room,
      target: "game-center",
      html: game_center_html
    )

    Turbo::StreamsChannel.broadcast_update_to(
      room,
      target: "scoreboard",
      partial: "rooms/scoreboard",
      locals: { room: room, turn: turn }
    )

    round = turn.round
    turns_count = round.turns.count
    memberships_count = room.room_memberships.count
    Rails.logger.info(
      "[BroadcastTurnEnded] room_id=#{room.id} round_id=#{round.id} turn_id=#{turn.id} " \
      "turns_in_round=#{turns_count} room_memberships=#{memberships_count}"
    )

    round_complete = turns_count == memberships_count
    max_rounds = (room.config["rounds"] || 8).to_i
    game_over = round_complete && round.round_number >= max_rounds

    if game_over
      Rails.logger.info("[BroadcastTurnEnded] branch=game_over")
      room.update(status: "ended")

      final_scores = room.scores.includes(:user).order(points: :desc)

      scores_html = final_scores.each_with_index.map do |score, index|
        rank = index + 1
        medal = case rank
                when 1 then "<span class='text-4xl'>&#x1F947;</span>"
                when 2 then "<span class='text-3xl'>&#x1F948;</span>"
                when 3 then "<span class='text-3xl'>&#x1F949;</span>"
                else "<span class='font-headline font-black text-2xl text-on-surface-variant'>##{rank}</span>"
                end

        highlight = rank == 1 ? "bg-primary-container border-primary scale-105" : "bg-surface-container-lowest border-on-surface"

        "<div class='flex items-center justify-between p-4 #{highlight} border-4 shadow-[4px_4px_0px_0px_#2d2f2f]'>
          <div class='flex items-center gap-4'>
            #{medal}
            <div class='w-12 h-12 bg-primary-container border-4 border-on-surface flex items-center justify-center font-headline font-black text-xl'>
              #{score.user.username.first.upcase}
            </div>
            <span class='font-headline font-bold text-lg uppercase'>#{score.user.username}</span>
          </div>
          <span class='font-headline font-black text-3xl text-primary'>#{score.points}</span>
        </div>"
      end.join

      game_over_html = "
        <section class='flex-1 flex flex-col items-center justify-center gap-8 p-8' id='game-center'>
          <div class='text-center'>
            <p class='font-headline font-bold text-sm uppercase tracking-widest text-on-surface-variant mb-2'>Game Over</p>
            <h2 class='font-headline font-black text-6xl uppercase text-primary tracking-widest'>Final Scores</h2>
          </div>
          <div class='w-full max-w-lg flex flex-col gap-3'>
            #{scores_html}
          </div>
        </section>
      "

      Turbo::StreamsChannel.broadcast_replace_to(
        room,
        target: "game-center",
        html: game_over_html
      )

      Turbo::StreamsChannel.broadcast_replace_to(
        room,
        target: "game-timer",
        html: "<span id='game-timer' class='text-on-surface-variant font-headline font-black text-3xl leading-none'>--</span>"
      )

      Turbo::StreamsChannel.broadcast_replace_to(
        room,
        target: "chat-input",
        html: "<div id='chat-input' class='p-3 bg-surface-container border-t-4 border-on-surface'>
          <div class='w-full p-3 bg-surface border-4 border-outline-variant text-on-surface-variant font-bold text-center text-sm uppercase opacity-60'>
            <span class='material-symbols-outlined text-sm align-middle'>sports_score</span>
            Game Over
          </div>
        </div>"
      )

      Turbo::StreamsChannel.broadcast_update_to(
        room,
        target: "word-display",
        html: "<span class='font-headline font-bold text-lg text-on-surface-variant uppercase'>Game Over</span>"
      )
    elsif round_complete
      Rails.logger.info("[BroadcastTurnEnded] branch=round_complete")
      Turbo::StreamsChannel.broadcast_replace_to(
        room,
        target: "game-center",
        html: "<section class='flex-1 flex items-center justify-center font-headline font-black text-4xl uppercase' id='game-center'>Round #{round.round_number} complete</section>"
      )
      start_next_round(room)
    else
      Rails.logger.info("[BroadcastTurnEnded] branch=next_turn")
      start_next_turn(room, round)
    end
  end

  private_class_method def self.start_next_round(room)
    return unless room.room_memberships.count >= 2

    round = room.rounds.create(round_number: room.rounds.count + 1)
    first_drawer = room.users_by_join_order.first

    turn = round.create_selecting_turn(drawer_user: first_drawer)
    return unless turn.persisted?

    broadcast_selecting_phase(room, turn)
  end

  private_class_method def self.start_next_turn(room, round)
    return unless room.room_memberships.count >= 2

    last_turn = round.turns.order(:id).last
    return unless last_turn&.status == "completed"

    drawer = room.next_drawer_after(last_turn.user)
    turn = round.create_selecting_turn(drawer_user: drawer)
    return unless turn.persisted?

    broadcast_selecting_phase(room, turn)
  end

  private_class_method def self.broadcast_selecting_phase(room, turn)
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
