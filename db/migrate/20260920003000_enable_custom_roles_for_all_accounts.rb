class EnableCustomRolesForAllAccounts < ActiveRecord::Migration[7.1]
  def up
    update_installation_default
    enable_for_existing_accounts

    GlobalConfig.clear_cache
  end

  private

  # New accounts read their features from this config, not from features.yml directly.
  def update_installation_default
    config = InstallationConfig.find_by(name: 'ACCOUNT_LEVEL_FEATURE_DEFAULTS')
    return if config.blank? || config.value.blank?

    config.value = config.value.map do |feature|
      feature['name'] == 'custom_roles' ? feature.merge('enabled' => true).except('premium') : feature
    end
    config.save!
  end

  def enable_for_existing_accounts
    Account.find_in_batches(batch_size: 100) do |accounts|
      accounts.each { |account| account.enable_features!('custom_roles') }
    end
  end
end
