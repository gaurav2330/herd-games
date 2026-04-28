class RoomsController < ApplicationController

  def create
    @room = Room.new(
      game_id: params[:game_id],
      admin: current_user,
      status: "drafted",
      code: SecureRandom.alphanumeric(6).upcase,
      config: default_config
    )
    if @room.save
      @room.room_memberships.create(user: current_user)
      redirect_to @room
    else
      redirect_to game_path(params[:game_id]), alert: "Failed to create room"
    end
  end

  def show
    @room = Room.includes(room_memberships: :user).find(params[:id])
  end

  def update
    @room = Room.find(params[:id])
    @room.update(config: params[:room][:config])
    redirect_to @room
  end

  def join
    @room = Room.find_by(code: params[:code])
    if @room
      Rails.logger.info "=== JOIN: Found room #{@room.id} for code #{params[:code]}"
      
      unless RoomMembership.exists?(room: @room, user: current_user)
        Rails.logger.info "=== JOIN: Creating membership for user #{current_user.id}"
        RoomMembership.create(room: @room, user: current_user)
        Rails.logger.info "=== JOIN: Membership created"
      end
      
      Rails.logger.info "=== JOIN: Broadcasting players list"
      Turbo::StreamsChannel.broadcast_update_to(
        @room,
        target: "players_list",
        partial: "rooms/players_list",
        locals: { room: @room }
      )
      Rails.logger.info "=== JOIN: Broadcast complete, redirecting"
      
      redirect_to @room
    else
      Rails.logger.error "=== JOIN: Room not found for code #{params[:code]}"
      redirect_to games_path, alert: "Room not found"
    end
  rescue => e
    Rails.logger.error "=== JOIN ERROR: #{e.class} - #{e.message}"
    Rails.logger.error e.backtrace.first(5).join("\n")
    raise
  end

  def start
    @room = Room.find(params[:id])
    
    # only admin can start
    return redirect_to @room, alert: "Not authorized" unless current_user == @room.admin
    
    # need at least 2 players
    return redirect_to @room, alert: "Need at least 2 players" unless @room.room_memberships.count >= 2
  
    # update room status
    @room.update(status: "active")
  
    # create first round
    round = @room.rounds.create(round_number: 1)
  
    # pick random drawer
    # first_drawer = @room.room_memberships.order("RANDOM()").first.user
    first_drawer = @room.room_memberships.last.user
  
    # pick 3 random words from game word list
    word_list = @room.game.config["word_list"]
    word_choices = word_list.sample(3)
  
    # create first turn
    turn =round.turns.create(
      user: first_drawer,
      word_choices: word_choices,
      status: "selecting",
      started_at: Time.current
    )

    word_selection_duration = @room.config["word_selection_duration"] || 10
    WordSelectionExpiredJob.set(wait: word_selection_duration.seconds).perform_later(turn.id)
  
    # broadcast redirect to all players
    Turbo::StreamsChannel.broadcast_replace_to(
      @room,
      target: "players_list",
      html: "<div id='players_list'><script>window.location.href='#{game_room_path(@room)}'</script></div>"
    )
  
    # redirect admin
    redirect_to game_room_path(@room)
  end

  def game
    @room = Room.find(params[:id])
    @current_round = @room.rounds.last
    @current_turn = @current_round&.turns&.last
    @is_drawer = @current_turn&.user == current_user
    @current_turn&.scores&.load # eager load scores
  end

  def word
    @room = Room.find(params[:id])
    @current_turn = @room.rounds.last.turns.last
    @current_turn.update(word: params[:word], status: "drawing", started_at: Time.current)
  
    # enqueue turn end job after turn duration
    turn_duration = (@room.config["turn_duration"] || 80).to_i
    TurnExpiredJob.set(wait: turn_duration.seconds).perform_later(@current_turn.id)
    
    # broadcast to everyone that drawing phase has started
    Turbo::StreamsChannel.broadcast_replace_to(
      @room,
      target: "game-center",
      partial: "rooms/drawing_phase",
      locals: { turn: @current_turn, is_drawer: false, room: @room }
    )

    Turbo::StreamsChannel.broadcast_update_to(
      @room,
      target: "word-display",
      html: "<span id='word-blanks' class='font-headline font-black text-2xl tracking-[0.4rem] text-on-surface'>#{@current_turn.word.gsub(/[a-zA-Z]/, '_ ').strip}</span><span id='word-actual' class='font-headline font-black text-2xl tracking-widest uppercase text-primary hidden'>#{@current_turn.word}</span><span class='text-xs font-bold uppercase text-on-surface-variant'>#{@current_turn.word.length} letters</span>"
    )

    Turbo::StreamsChannel.broadcast_update_to(
      @current_turn.user,
      target: "word-display",
      html: "<span id='word-actual' class='font-headline font-black text-2xl tracking-widest uppercase text-primary'>#{@current_turn.word}</span>"
    )
  
    Turbo::StreamsChannel.broadcast_replace_to(
      @room,
      target: "game-timer",
      html: "<span id='game-timer' data-controller='timer' data-timer-seconds-value='#{@room.config["turn_duration"] || 80}' class='text-primary font-headline font-black text-3xl leading-none'>#{@room.config["turn_duration"] || 80}</span>"
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
  
    head :ok
  end

  private

  def default_config
    {
      turn_duration: 80,
      max_players: 10,
      rounds: 8,
      word_options: 3,
      word_selection_duration: 10
    }
  end
end
