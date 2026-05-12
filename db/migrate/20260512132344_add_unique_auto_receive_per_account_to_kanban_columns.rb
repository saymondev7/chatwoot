class AddUniqueAutoReceivePerAccountToKanbanColumns < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!

  def up
    duplicates = KanbanColumn
                 .unscoped
                 .where(column_function: 1)
                 .group(:account_id)
                 .having('COUNT(*) > 1')
                 .pluck(:account_id)

    if duplicates.any?
      raise "Accounts com múltiplas auto_receive: #{duplicates.inspect}. " \
            'Resolver manualmente antes de aplicar a constraint.'
    end

    add_index :kanban_columns,
              :account_id,
              unique: true,
              where: 'column_function = 1',
              name: 'index_kanban_columns_on_account_id_auto_receive_unique',
              algorithm: :concurrently
  end

  def down
    remove_index :kanban_columns,
                 name: 'index_kanban_columns_on_account_id_auto_receive_unique',
                 algorithm: :concurrently
  end
end
