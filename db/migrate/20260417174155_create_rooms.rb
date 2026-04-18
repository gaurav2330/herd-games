class CreateRooms < ActiveRecord::Migration[8.1]
  def change
    create_table :rooms do |t|
      t.references :game, null: false, foreign_key: true
      t.references :squad, foreign_key: true
      t.references :admin, null: false, foreign_key: { to_table: :users }
      t.string :code
      t.string :status
      t.jsonb :config

      t.timestamps
    end
  end
end