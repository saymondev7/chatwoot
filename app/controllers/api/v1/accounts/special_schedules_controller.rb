class Api::V1::Accounts::SpecialSchedulesController < Api::V1::Accounts::BaseController
  DEFAULT_TIMEZONE = 'America/Sao_Paulo'.freeze
  DEFAULT_LOOKUP_DAYS = 7

  before_action :require_admin_role!, except: [:lookup]
  before_action :fetch_special_schedule, only: [:update, :destroy]

  def index
    @special_schedules = Current.account.special_schedules.ordered
    render json: @special_schedules.map { |schedule| schedule_json(schedule) }
  end

  def create
    @special_schedule = Current.account.special_schedules.new(special_schedule_params)
    @special_schedule.save!
    render json: schedule_json(@special_schedule), status: :created
  end

  def update
    @special_schedule.update!(special_schedule_params)
    render json: schedule_json(@special_schedule)
  end

  def destroy
    @special_schedule.destroy!
    head :no_content
  end

  # Consumed by the n8n agent: returns the ready-to-send message for a date,
  # plus the exceptions coming up in the next `days` days.
  def lookup
    date = lookup_date
    return render json: { error: I18n.t('errors.special_schedules.invalid_date') }, status: :bad_request if date.blank?

    today = Current.account.special_schedules.active.on_date(date).ordered
    upcoming = Current.account.special_schedules.active.in_range(date + 1, date + lookup_days).ordered

    render json: {
      date: date,
      timezone: timezone.name,
      has_exception: today.any?,
      today: today.map { |schedule| lookup_json(schedule) },
      upcoming: upcoming.map { |schedule| lookup_json(schedule) }
    }
  end

  private

  def require_admin_role!
    render json: { error: 'Access denied. Admin privileges required.' }, status: :forbidden unless Current.account_user&.administrator?
  end

  def fetch_special_schedule
    @special_schedule = Current.account.special_schedules.find(params[:id])
  end

  def special_schedule_params
    params.require(:special_schedule).permit(
      :name, :starts_on, :ends_on, :schedule_type, :message, :enabled,
      :open_hour, :open_minutes, :close_hour, :close_minutes
    )
  end

  def timezone
    Time.find_zone(params[:timezone]) || Time.find_zone(DEFAULT_TIMEZONE)
  end

  def lookup_date
    return Time.current.in_time_zone(timezone).to_date if params[:date].blank?

    Date.parse(params[:date])
  rescue Date::Error
    nil
  end

  def lookup_days
    days = params[:days].presence&.to_i || DEFAULT_LOOKUP_DAYS
    days.clamp(0, 90)
  end

  def hours_label(schedule)
    return nil unless schedule.custom_hours?

    format('%<oh>02d:%<om>02d - %<ch>02d:%<cm>02d', oh: schedule.open_hour, om: schedule.open_minutes,
                                                    ch: schedule.close_hour, cm: schedule.close_minutes)
  end

  def lookup_json(schedule)
    {
      name: schedule.name,
      type: schedule.schedule_type,
      starts_on: schedule.starts_on,
      ends_on: schedule.ends_on,
      hours: hours_label(schedule),
      message: schedule.message
    }
  end

  def schedule_json(schedule)
    {
      id: schedule.id,
      name: schedule.name,
      starts_on: schedule.starts_on,
      ends_on: schedule.ends_on,
      schedule_type: schedule.schedule_type,
      open_hour: schedule.open_hour,
      open_minutes: schedule.open_minutes,
      close_hour: schedule.close_hour,
      close_minutes: schedule.close_minutes,
      message: schedule.message,
      enabled: schedule.enabled,
      created_at: schedule.created_at,
      updated_at: schedule.updated_at
    }
  end
end
