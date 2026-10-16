class CreateTeams < ActiveRecord::Migration[8.0]
  def change
    create_table :teams do |t|
      t.string :name, null: false
      t.string :short_name
      t.string :slug, null: false
      t.string :city

      t.timestamps
    end
    add_index :teams, :slug, unique: true
  end
end
