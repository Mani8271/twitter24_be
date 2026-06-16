class BusinessLocationSerializer
  include FastJsonapi::ObjectSerializer

  attributes :map_address, :latitude, :longitude, :place_id,
             :address_line1, :address_line2, :city, :state, :pin_code,
             :address_last_updated_at

  # Include cooldown information
  attribute :address_cooldown_active do |object|
    object.address_cooldown_active?
  end

  attribute :next_address_update_date do |object|
    object.next_address_update_date&.strftime("%d %B %Y")
  end

  attribute :days_until_next_address_update do |object|
    object.days_until_next_address_update
  end

  attribute :cooldown_message do |object|
    if object.address_cooldown_active?
      days = object.days_until_next_address_update
      next_date = object.next_address_update_date&.strftime("%d %B %Y")
      "Your business address was recently updated. You can change it again after #{days} day(s) (on #{next_date})"
    else
      nil
    end
  end
end
