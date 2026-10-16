class CreateMatchReports < ActiveRecord::Migration[8.0]
  def change
    create_table :match_reports do |t|
      t.references :match, null: false, foreign_key: true
      t.string :source, null: false
      t.integer :home_goals
      t.integer :away_goals
      t.integer :home_penalties
      t.integer :away_penalties
      t.string :walkover_winner
      t.boolean :postponed, null: false, default: false
      t.datetime :reported_at, null: false

      t.timestamps
    end
    add_index :match_reports, [ :match_id, :source ], unique: true
  end
end
