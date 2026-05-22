class Api::V1::Accounts::Kanban::MacrosController < Api::V1::Accounts::BaseController
  before_action :require_admin_role!
  before_action :fetch_macro, only: %i[show update destroy restore]

  def index
    @macros = Current.account.kanban_macros.ordered
    render json: macros_json(@macros)
  end

  def show
    render json: macro_json(@macro)
  end

  def create
    @macro = Current.account.kanban_macros.new(macro_params)
    @macro.save!
    render json: macro_json(@macro), status: :created
  end

  def update
    @macro.update!(macro_params)
    render json: macro_json(@macro)
  end

  def destroy
    if @macro.system?
      render json: { error: I18n.t('errors.kanban.macros.system_macro_cannot_be_deleted') }, status: :forbidden
      return
    end
    @macro.destroy!
    head :no_content
  end

  def schema
    payload = build_schema_payload
    fresh_when(etag: payload, public: false)
    render json: payload
  end

  def restore
    unless @macro.system?
      render json: { error: I18n.t('errors.kanban.macros.restore_only_for_system_macros') }, status: :unprocessable_entity
      return
    end
    default = Kanban::Macros::Seeder.find_default_by_name(@macro.name)
    raise ActiveRecord::RecordNotFound, 'definição padrão não encontrada' unless default

    @macro.update!(
      triggers: default[:triggers],
      conditions: default[:conditions],
      actions: default[:actions]
    )
    render json: macro_json(@macro)
  end

  private

  def require_admin_role!
    render json: { error: 'Access denied. Admin privileges required.' }, status: :forbidden unless Current.account_user&.administrator?
  end

  def fetch_macro
    @macro = Current.account.kanban_macros.find(params[:id])
  end

  def macro_params
    permitted = params.require(:macro).permit(:name, :description, :enabled, :position)
    %i[triggers conditions actions].each do |key|
      raw = params.dig(:macro, key)
      next unless raw.is_a?(Array) || (raw.respond_to?(:each) && !raw.is_a?(String))

      permitted[key] = raw.map do |item|
        {
          'type' => item[:type] || item['type'],
          'config' => (item[:config] || item['config'] || {}).to_unsafe_h
        }
      end
    end
    permitted
  end

  def build_schema_payload
    {
      triggers: Kanban::Macros::Triggers::Registry.all.map { |k| serialize_class(k) },
      conditions: Kanban::Macros::Conditions::Registry.all.map { |k| serialize_class(k) },
      actions: Kanban::Macros::Actions::Registry.all.map { |k| serialize_class(k) }
    }
  end

  def serialize_class(klass)
    { type: klass.key, label: klass.label, config_schema: klass.config_schema }
  end

  def macros_json(macros)
    macros.map { |m| macro_json(m) }
  end

  def macro_json(macro)
    {
      id: macro.id,
      name: macro.name,
      description: macro.description,
      enabled: macro.enabled,
      position: macro.position,
      system: macro.system,
      triggers: macro.triggers,
      conditions: macro.conditions,
      actions: macro.actions,
      created_at: macro.created_at,
      updated_at: macro.updated_at
    }
  end
end
