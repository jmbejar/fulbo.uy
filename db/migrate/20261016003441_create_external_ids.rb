class CreateExternalIds < ActiveRecord::Migration[8.0]
  def change
    create_table :external_ids do |t|
      t.string :source, null: false
      t.string :external_id, null: false
      t.references :identifiable, polymorphic: true, null: false

      t.timestamps
    end
    add_index :external_ids, [ :source, :external_id, :identifiable_type ], unique: true
  end
end
