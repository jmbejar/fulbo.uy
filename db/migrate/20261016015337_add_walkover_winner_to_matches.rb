class AddWalkoverWinnerToMatches < ActiveRecord::Migration[8.0]
  def change
    add_column :matches, :walkover_winner, :string
  end
end
