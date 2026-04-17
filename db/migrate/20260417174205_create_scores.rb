class CreateScores < ActiveRecord::Migration[8.1]
  def change
    create_table :scores do |t|
      t.references :user, null: false, foreign_key: true
      t.references :scoreable, polymorphic: true, null: false
      t.integer :points

      t.timestamps
    end
  end
end
