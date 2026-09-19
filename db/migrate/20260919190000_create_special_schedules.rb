class CreateSpecialSchedules < ActiveRecord::Migration[7.1]
  def change
    create_table :special_schedules do |t|
      t.references :account, null: false, foreign_key: { on_delete: :cascade }, index: false
      t.string :name, null: false
      t.date :starts_on, null: false
      t.date :ends_on, null: false
      t.integer :schedule_type, null: false, default: 0
      t.integer :open_hour
      t.integer :open_minutes
      t.integer :close_hour
      t.integer :close_minutes
      t.text :message, null: false
      t.boolean :enabled, null: false, default: true

      t.timestamps
    end

    add_index :special_schedules, [:account_id, :starts_on, :ends_on]
  end
end
