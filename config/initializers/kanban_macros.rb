Rails.application.config.to_prepare do
  Kanban::Macros::Triggers::Registry.reset!
  Kanban::Macros::Conditions::Registry.reset!
  Kanban::Macros::Actions::Registry.reset!

  trigger_classes = [
    # Kanban::Macros::Triggers::LeadMessageReceived (PR3)
  ]
  condition_classes = [
    # Kanban::Macros::Conditions::CardNotInColumnFunction (PR3)
    # Kanban::Macros::Conditions::ConversationStatusIs (PR3)
    # Kanban::Macros::Conditions::MessageSenderIsLead (PR3)
  ]
  action_classes = [
    # Kanban::Macros::Actions::MoveCardToColumnFunction (PR3)
  ]

  trigger_classes.each { |k| Kanban::Macros::Triggers::Registry.register(k) }
  condition_classes.each { |k| Kanban::Macros::Conditions::Registry.register(k) }
  action_classes.each { |k| Kanban::Macros::Actions::Registry.register(k) }
end
