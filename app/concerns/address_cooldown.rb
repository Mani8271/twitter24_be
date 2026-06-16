module AddressCooldown
  extend ActiveSupport::Concern

  # Cooldown period in days (configurable via ENV)
  ADDRESS_COOLDOWN_DAYS = ENV.fetch("ADDRESS_COOLDOWN_DAYS", "30").to_i

  included do
    validate :validate_address_cooldown, if: -> { address_changed? && persisted? }
    attr_accessor :bypass_address_cooldown  # Allow bypass for admins
  end

  def address_changed?
    map_address_changed? || latitude_changed? || longitude_changed? ||
      address_line1_changed? || address_line2_changed? ||
      city_changed? || state_changed? || pin_code_changed?
  end

  def validate_address_cooldown
    return if address_last_updated_at.nil? # First time setting address
    return if bypass_address_cooldown # Allow bypass for admins

    last_update = address_last_updated_at
    next_allowed_update = last_update + ADDRESS_COOLDOWN_DAYS.days
    days_remaining = ((next_allowed_update - Time.current) / 1.day).ceil

    if Time.current < next_allowed_update && days_remaining > 0
      formatted_date = next_allowed_update.strftime("%d %B %Y")
      errors.add(
        :address,
        "was recently updated. You can change it again after #{days_remaining} day(s) (on #{formatted_date})"
      )
    end
  end

  def address_cooldown_active?
    return false if address_last_updated_at.nil?

    next_allowed_update = address_last_updated_at + ADDRESS_COOLDOWN_DAYS.days
    Time.current < next_allowed_update
  end

  def next_address_update_date
    return nil if address_last_updated_at.nil?
    address_last_updated_at + ADDRESS_COOLDOWN_DAYS.days
  end

  def days_until_next_address_update
    return 0 if address_last_updated_at.nil?

    next_date = next_address_update_date
    days = ((next_date - Time.current) / 1.day).ceil
    days > 0 ? days : 0
  end

  def cooldown_message
    if address_cooldown_active?
      days = days_until_next_address_update
      next_date = next_address_update_date&.strftime("%d %B %Y")
      "Your business address was recently updated. You can change it again after #{days} day(s) (on #{next_date})"
    else
      nil
    end
  end
end
