namespace :kanban do
  desc 'Archive all cards from resolved conversations (one-shot cleanup)'
  task archive_resolved: :environment do
    Account.find_each do |account|
      count = account.kanban_cards
        .joins(:conversation)
        .where(conversations: { status: :resolved })
        .where(archived_at: nil)
        .update_all(archived_at: Time.current)
      puts "Account #{account.id}: arquivados #{count} cards"
    end
  end
end
