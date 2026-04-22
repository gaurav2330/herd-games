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
      RoomMembership.find_or_create_by(room: @room, user: current_user)
      puts "Broadcasting update to players list"
      Turbo::StreamsChannel.broadcast_update_to(
        @room,
        target: "players_list",
        partial: "rooms/players_list",
        locals: { room: @room }
      )
      puts "Update broadcasted"
      redirect_to @room
    else
      redirect_to games_path, alert: "Room not found"
    end
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
    round.turns.create(
      user: first_drawer,
      word_choices: word_choices,
      status: "selecting",
      started_at: Time.current
    )
  
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
  end

  def word
    @room = Room.find(params[:id])
    @current_turn = @room.rounds.last.turns.last
    @current_turn.update(word: params[:word], status: "drawing")
    
    # broadcast to everyone that drawing phase has started
    Turbo::StreamsChannel.broadcast_replace_to(
      @room,
      target: "game-center",
      partial: "rooms/drawing_phase",
      locals: { turn: @current_turn, is_drawer: false }
    )
    
    redirect_to game_room_path(@room)
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
