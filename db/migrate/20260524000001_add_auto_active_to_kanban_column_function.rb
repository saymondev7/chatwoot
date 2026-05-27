class AddAutoActiveToKanbanColumnFunction < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!

  def up
    # column_function integer values: no_function=0, auto_receive=1, auto_won=2, auto_lost=3, auto_active=4
    # No new DB column needed — enum lives in the Rails model (integer field already exists).
    # Only the partial unique index is needed to enforce 1 auto_active per account.

    duplicates = KanbanColumn
                 .unscoped
                 .where(column_function: 4)
                 .group(:account_id)
                 .having('COUNT(*) > 1')
                 .pluck(:account_id)

    if duplicates.any?
      raise "Accounts com múltiplas colunas com column_function=4 (auto_active): #{duplicates.inspect}. " \
            'Resolver manualmente antes de aplicar a constraint.'
    end

    add_index :kanban_columns,
              :account_id,
              unique: true,
              where: 'column_function = 4',
              name: 'index_kanban_columns_on_account_id_auto_active_unique',
              algorithm: :concurrently
  end

  def down
    remove_index :kanban_columns,
                 name: 'index_kanban_columns_on_account_id_auto_active_unique',
                 algorithm: :concurrently
    # Reset any auto_active columns back to no_function before reverting
    KanbanColumn.unscoped.where(column_function: 4).update_all(column_function: 0) # rubocop:disable Rails/SkipsModelValidations
  end
end
