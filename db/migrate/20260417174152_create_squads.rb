class CreateSquads < ActiveRecord::Migration[8.1]
  def change
    create_table :squads do |t|
      t.string :name
      t.text :description
      t.references :admin, null: false, foreign_key: { to_table: :users }

      t.timestamps
    end
  end
end
