class CreateTurns < ActiveRecord::Migration[8.1]
  def change
    create_table :turns do |t|
      t.references :round, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.string :word
      t.datetime :started_at
      t.datetime :ended_at

      t.timestamps
    end
  end
end
