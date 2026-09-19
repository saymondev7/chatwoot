class AddHiddenSidebarItemsToCustomRoles < ActiveRecord::Migration[7.0]
  def change
    add_column :custom_roles, :hidden_sidebar_items, :text, array: true, default: []
  end
end
