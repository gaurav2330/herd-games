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

    if turns_count == memberships_count && round.round_number <= room.config["rounds"]
      Rails.logger.info("[BroadcastTurnEnded] branch=round_complete (counts equal)")
      Turbo::StreamsChannel.broadcast_replace_to(
        room,
        target: "game-center",
        html: "<section class='flex-1 flex items-center justify-center font-headline font-black text-4xl uppercase' id='game-center'>Round #{round.round_number} complete</section>"
      )
      NextRoundJob.set(wait: 3.seconds).perform_later(room.id)
    else
      Rails.logger.info("[BroadcastTurnEnded] branch=next_turn_job")
      NextTurnJob.set(wait: 3.seconds).perform_later(room.id, round.id)
    end
  end
end
