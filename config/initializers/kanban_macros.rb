Rails.application.config.to_prepare do
  Kanban::Macros::Triggers::Registry.reset!
  Kanban::Macros::Conditions::Registry.reset!
  Kanban::Macros::Actions::Registry.reset!

  trigger_classes = [
    Kanban::Macros::Triggers::LeadMessageReceived,
    Kanban::Macros::Triggers::ConversationReopened
  ]
  condition_classes = [
    Kanban::Macros::Conditions::CardNotInColumnFunction,
    Kanban::Macros::Conditions::ConversationStatusIs,
    Kanban::Macros::Conditions::MessageSenderIsLead
  ]
  action_classes = [
    Kanban::Macros::Actions::MoveCardToColumnFunction
  ]

  trigger_classes.each { |k| Kanban::Macros::Triggers::Registry.register(k) }
  condition_classes.each { |k| Kanban::Macros::Conditions::Registry.register(k) }
  action_classes.each { |k| Kanban::Macros::Actions::Registry.register(k) }
end
