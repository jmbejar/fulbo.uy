class CreateTeamAliases < ActiveRecord::Migration[8.0]
  def change
    create_table :team_aliases do |t|
      t.references :team, null: false, foreign_key: true
      t.string :name, null: false

      t.timestamps
    end
    add_index :team_aliases, :name, unique: true
  end
end
