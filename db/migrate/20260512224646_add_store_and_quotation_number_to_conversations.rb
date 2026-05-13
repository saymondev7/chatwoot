class AddStoreAndQuotationNumberToConversations < ActiveRecord::Migration[7.0]
  def change
    add_column :conversations, :store, :integer
    add_column :conversations, :quotation_number, :string, limit: 6
  end
end
