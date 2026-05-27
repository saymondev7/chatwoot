class Kanban::Macros::Seeder
  DEFAULTS = [
    {
      name: 'Lead enviou mensagem',
      description: 'Move o card para a coluna de aguardando atendimento quando o lead responde enquanto o time está em atendimento ativo.',
      triggers: [
        { 'type' => 'lead_message_received', 'config' => {} }
      ],
      conditions: [
        { 'type' => 'conversation_status_is', 'config' => { 'status' => 'open' } },
        { 'type' => 'message_sender_is_lead', 'config' => {} }
      ],
      actions: [
        { 'type' => 'move_card_to_column_function', 'config' => { 'column_function' => 'auto_receive' } }
      ]
    },
    {
      name: 'Mensagem enviada pelo time',
      description: 'Move o card para a coluna de atendimento ativo quando o time responde.',
      triggers: [
        { 'type' => 'message_received_from_team', 'config' => {} }
      ],
      conditions: [
        { 'type' => 'conversation_status_is', 'config' => { 'status' => 'open' } }
      ],
      actions: [
        { 'type' => 'move_card_to_column_function', 'config' => { 'column_function' => 'auto_active' } }
      ]
    }
  ].freeze

  def self.find_default_by_name(name)
    DEFAULTS.find { |spec| spec[:name] == name }
  end

  def initialize(account)
    @account = account
  end

  def seed_defaults!
    DEFAULTS.each do |spec|
      next if Kanban::Macro.exists?(account: @account, name: spec[:name], system: true)

      Kanban::Macro.create!(spec.merge(account: @account, system: true, enabled: true, position: 0))
    end
  end
end
