class AddStatusToTurns < ActiveRecord::Migration[8.1]
  def change
    add_column :turns, :status, :string
  end
end
