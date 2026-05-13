class SeedDefaultKanbanMacro < ActiveRecord::Migration[7.1]
  def up
    Account.find_each do |account|
      Kanban::Macros::Seeder.new(account).seed_defaults!
    end
  end

  def down
    Kanban::Macro.where(system: true, name: 'Lead enviou mensagem').delete_all
  end
end
