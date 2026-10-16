class CreateHistoricalRecords < ActiveRecord::Migration[8.0]
  def change
    create_table :historical_records do |t|
      t.references :team, null: false, foreign_key: true
      t.references :competition, null: false, foreign_key: true
      t.integer :year, null: false
      t.integer :points, null: false, default: 0
      t.integer :matches_played, null: false, default: 0

      t.timestamps
    end
    add_index :historical_records, [ :competition_id, :team_id, :year ], unique: true
  end
end
