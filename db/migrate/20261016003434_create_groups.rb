class CreateGroups < ActiveRecord::Migration[8.0]
  def change
    create_table :groups do |t|
      t.references :stage, null: false, foreign_key: true
      t.string :name, null: false
      t.integer :position

      t.timestamps
    end
  end
end
