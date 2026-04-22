class AddWordChoicesToTurns < ActiveRecord::Migration[8.1]
  def change
    add_column :turns, :word_choices, :jsonb
  end
end
