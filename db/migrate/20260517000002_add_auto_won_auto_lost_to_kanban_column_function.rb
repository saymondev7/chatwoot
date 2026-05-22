class AddAutoWonAutoLostToKanbanColumnFunction < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!

  def up
    # column_function integer values: no_function=0, auto_receive=1, auto_won=2, auto_lost=3
    # Check for pre-existing duplicates before adding unique constraints
    [2, 3].each do |function_value|
      duplicates = KanbanColumn
                   .unscoped
                   .where(column_function: function_value)
                   .group(:account_id)
                   .having('COUNT(*) > 1')
                   .pluck(:account_id)

      if duplicates.any?
        raise "Accounts com múltiplas colunas com column_function=#{function_value}: #{duplicates.inspect}. " \
              'Resolver manualmente antes de aplicar a constraint.'
      end
    end

    add_index :kanban_columns,
              :account_id,
              unique: true,
              where: 'column_function = 2',
              name: 'index_kanban_columns_on_account_id_auto_won_unique',
              algorithm: :concurrently

    add_index :kanban_columns,
              :account_id,
              unique: true,
              where: 'column_function = 3',
              name: 'index_kanban_columns_on_account_id_auto_lost_unique',
              algorithm: :concurrently
  end

  def down
    remove_index :kanban_columns,
                 name: 'index_kanban_columns_on_account_id_auto_won_unique',
                 algorithm: :concurrently
    remove_index :kanban_columns,
                 name: 'index_kanban_columns_on_account_id_auto_lost_unique',
                 algorithm: :concurrently
  end
end
