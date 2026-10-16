class CreateCompetitions < ActiveRecord::Migration[8.0]
  def change
    create_table :competitions do |t|
      t.string :name, null: false
      t.string :slug, null: false
      t.integer :tier, null: false

      t.timestamps
    end
    add_index :competitions, :slug, unique: true
  end
end
