class CreateSeasons < ActiveRecord::Migration[8.0]
  def change
    create_table :seasons do |t|
      t.references :competition, null: false, foreign_key: true
      t.integer :year, null: false
      t.string :official_name
      t.boolean :current, null: false, default: false
      t.json :annual_zones, null: false
      t.json :relegation_zones, null: false
      t.integer :relegation_years, null: false, default: 0

      t.timestamps
    end
    add_index :seasons, [ :competition_id, :year ], unique: true
  end
end
