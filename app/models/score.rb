class Score < ApplicationRecord
  belongs_to :user
  belongs_to :scoreable, polymorphic: true

  after_create :update_round_score, if: :turn_score?
  after_create :update_room_score, if: :round_score?

  private

  def turn_score?
    scoreable_type == "Turn"
  end

  def round_score?
    scoreable_type == "Round"
  end

  def update_round_score
    round = scoreable.round
    round_score = Score.find_or_initialize_by(user: user, scoreable: round)
    round_score.points = Score.where(user: user, scoreable: round.turns).sum(:points)
    round_score.save!
  end

  def update_room_score
    room = scoreable.room
    room_score = Score.find_or_initialize_by(user: user, scoreable: room)
    room_score.points = Score.where(user: user, scoreable: room.rounds).sum(:points)
    room_score.save!
  end
end
