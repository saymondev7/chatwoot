class AddArchivedAtToKanbanCards < ActiveRecord::Migration[7.1]
  def change
    add_column :kanban_cards, :archived_at, :datetime, null: true
    add_index :kanban_cards, :archived_at
  end
end
