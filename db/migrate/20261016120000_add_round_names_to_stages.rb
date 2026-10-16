class AddRoundNamesToStages < ActiveRecord::Migration[8.0]
  def change
    # Knockout stages name their rounds ("Octavos de final") instead of
    # numbering them.
    add_column :stages, :round_names, :json, null: false, default: []
  end
end
