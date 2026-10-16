class CreatePointsAdjustments < ActiveRecord::Migration[8.0]
  def change
    create_table :points_adjustments do |t|
      t.references :team, null: false, foreign_key: true
      t.references :stage, null: false, foreign_key: true
      t.integer :points, null: false
      t.string :reason

      t.timestamps
    end
  end
end
