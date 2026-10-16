class CreateStages < ActiveRecord::Migration[8.0]
  def change
    create_table :stages do |t|
      t.references :season, null: false, foreign_key: true
      t.string :name, null: false
      t.string :slug, null: false
      t.integer :position, null: false, default: 0
      t.string :format, null: false, default: "round_robin"
      t.boolean :counts_for_annual, null: false, default: false
      t.boolean :current, null: false, default: false
      t.json :tiebreakers, null: false
      t.json :zones, null: false

      t.timestamps
    end
    add_index :stages, [ :season_id, :slug ], unique: true
  end
end
