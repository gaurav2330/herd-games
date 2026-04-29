class Round < ApplicationRecord
  belongs_to :room
  has_many :turns, dependent: :destroy
  has_many :scores, as: :scoreable, dependent: :destroy

  # Creates a turn in "selecting" and schedules WordSelectionExpiredJob.
  def create_selecting_turn(drawer_user:)
    word_list = room.game.config["word_list"] || []
    word_choices = word_list.sample(3)

    turn = turns.create(
      user: drawer_user,
      word_choices: word_choices,
      status: "selecting",
      started_at: Time.current
    )
    return turn unless turn.persisted?

    word_selection_duration = room.config["word_selection_duration"] || 10
    WordSelectionExpiredJob.set(wait: word_selection_duration.seconds).perform_later(turn.id)

    turn
  end
end
