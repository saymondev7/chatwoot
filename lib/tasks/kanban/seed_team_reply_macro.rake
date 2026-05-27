namespace :kanban do
  desc 'Seed macro "Mensagem enviada pelo time" para todas as contas (idempotente)'
  task seed_team_reply_macro: :environment do
    count = 0
    Account.find_each do |account|
      Kanban::Macros::Seeder.new(account).seed_defaults!
      count += 1
      print '.' if (count % 100).zero?
    end
    puts "\nConcluído. #{count} contas processadas."
  end
end
