# == Schema Information
#
# Table name: kanban_macros
#
#  id          :bigint           not null, primary key
#  actions     :jsonb            not null
#  conditions  :jsonb            not null
#  description :text
#  enabled     :boolean          default(TRUE), not null
#  name        :string           not null
#  position    :integer          default(0), not null
#  system      :boolean          default(FALSE), not null
#  triggers    :jsonb            not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  account_id  :bigint           not null
#
# Indexes
#
#  index_kanban_macros_on_account_id               (account_id)
#  index_kanban_macros_on_account_id_and_enabled   (account_id,enabled)
#  index_kanban_macros_on_account_id_and_position  (account_id,position)
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id) ON DELETE => cascade
#
class Kanban::Macro < ApplicationRecord
  self.table_name = 'kanban_macros'

  belongs_to :account

  validates :name, presence: true
  validate :triggers_present
  validate :actions_present
  validate :validate_triggers_structure
  validate :validate_conditions_structure
  validate :validate_actions_structure

  before_destroy :prevent_system_macro_deletion

  scope :enabled, -> { where(enabled: true) }
  scope :ordered, -> { order(:position, :id) }

  def trigger_objects
    Array(triggers).map { |t| Kanban::Macros::Triggers::Registry.build(t['type'], t['config']) }
  end

  def condition_objects
    Array(conditions).map { |c| Kanban::Macros::Conditions::Registry.build(c['type'], c['config']) }
  end

  def action_objects
    Array(actions).map { |a| Kanban::Macros::Actions::Registry.build(a['type'], a['config']) }
  end

  private

  def triggers_present
    errors.add(:triggers, 'precisa de ao menos um gatilho') if Array(triggers).empty?
  end

  def actions_present
    errors.add(:actions, 'precisa de ao menos uma ação') if Array(actions).empty?
  end

  def validate_triggers_structure
    validate_collection_structure(:triggers, Kanban::Macros::Triggers::Registry)
  end

  def validate_conditions_structure
    validate_collection_structure(:conditions, Kanban::Macros::Conditions::Registry)
  end

  def validate_actions_structure
    validate_collection_structure(:actions, Kanban::Macros::Actions::Registry)
  end

  def validate_collection_structure(attr, registry)
    Array(public_send(attr)).each do |item|
      type = item['type']
      klass = registry.fetch(type)
      if klass.nil?
        errors.add(attr, "tipo desconhecido: #{type}")
        next
      end

      begin
        klass.validate_config!(item['config'] || {})
      rescue ArgumentError => e
        errors.add(attr, "config inválido para #{type}: #{e.message}")
      end
    end
  end

  def prevent_system_macro_deletion
    return unless system?

    errors.add(:base, 'macros de sistema não podem ser deletados')
    throw :abort
  end
end
