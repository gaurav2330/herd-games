class Score < ApplicationRecord
  belongs_to :user
  belongs_to :scoreable, polymorphic: true

  after_create :update_round_score, if: :turn_score?

  private

  def turn_score?
    scoreable_type == "Turn"
  end

  def update_round_score
    round = scoreable.round
    round_score = Score.find_or_initialize_by(user: user, scoreable: round)
    round_score.points = Score.where(user: user, scoreable: round.turns).sum(:points)
    round_score.save!
  end
end
