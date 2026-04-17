class CreateSquadMemberships < ActiveRecord::Migration[8.1]
  def change
    create_table :squad_memberships do |t|
      t.references :squad, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
  end
end
