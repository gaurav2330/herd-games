class TurnExpiredJob < ApplicationJob
  queue_as :default

  def perform(turn_id)
    turn = Turn.find_by(id: turn_id)
    return unless turn
    return unless turn.status == "drawing"
  
    room = turn.round.room
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
  
    broadcast_turn_ended(turn, room, turn.scores.reload)
  end

  private

  def broadcast_turn_ended(turn, room, scores)
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
  
    # NextTurnJob.set(wait: 3.seconds).perform_later(room.id, turn.round.id)
  end
end