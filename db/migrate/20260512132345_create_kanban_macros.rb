class CreateKanbanMacros < ActiveRecord::Migration[7.1]
  def change
    create_table :kanban_macros do |t|
      t.references :account, null: false, foreign_key: { on_delete: :cascade }
      t.string :name, null: false
      t.text :description
      t.boolean :enabled, null: false, default: true
      t.integer :position, null: false, default: 0
      t.jsonb :triggers, null: false, default: []
      t.jsonb :conditions, null: false, default: []
      t.jsonb :actions, null: false, default: []
      t.boolean :system, null: false, default: false
      t.timestamps
    end

    add_index :kanban_macros, [:account_id, :enabled]
    add_index :kanban_macros, [:account_id, :position]
  end
end
