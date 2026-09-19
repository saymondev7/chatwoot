# == Schema Information
#
# Table name: special_schedules
#
#  id            :bigint           not null, primary key
#  close_hour    :integer
#  close_minutes :integer
#  enabled       :boolean          default(TRUE), not null
#  ends_on       :date             not null
#  message       :text             not null
#  name          :string           not null
#  open_hour     :integer
#  open_minutes  :integer
#  schedule_type :integer          default("closed"), not null
#  starts_on     :date             not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  account_id    :bigint           not null
#
# Indexes
#
#  idx_on_account_id_starts_on_ends_on_4fb5195aeb  (account_id,starts_on,ends_on)
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id) ON DELETE => cascade
#
class SpecialSchedule < ApplicationRecord
  belongs_to :account

  enum :schedule_type, { closed: 0, custom_hours: 1, promotion: 2, notice: 3 }

  validates :name, presence: true
  validates :message, presence: true
  validates :starts_on, presence: true
  validates :ends_on, presence: true
  validates :open_hour, :close_hour, presence: true, inclusion: 0..23, if: :custom_hours?
  validates :open_minutes, :close_minutes, presence: true, inclusion: 0..59, if: :custom_hours?
  validate :ends_on_after_starts_on
  validate :close_after_open, if: :custom_hours?

  scope :active, -> { where(enabled: true) }
  scope :on_date, ->(date) { where('starts_on <= :date AND ends_on >= :date', date: date) }
  scope :in_range, ->(from, to) { where('starts_on <= :to AND ends_on >= :from', from: from, to: to) }
  scope :ordered, -> { order(:starts_on, :id) }

  private

  def ends_on_after_starts_on
    return if starts_on.blank? || ends_on.blank? || ends_on >= starts_on

    errors.add(:ends_on, I18n.t('errors.special_schedules.ends_on_before_starts_on'))
  end

  def close_after_open
    return if open_hour.blank? || close_hour.blank? || open_minutes.blank? || close_minutes.blank?
    return if (close_hour.hours + close_minutes.minutes) > (open_hour.hours + open_minutes.minutes)

    errors.add(:close_hour, I18n.t('errors.special_schedules.close_before_open'))
  end
end
