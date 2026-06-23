class BusinessLocationSerializer < ActiveModel::Serializer
  attributes :map_address, :latitude, :longitude, :place_id,
             :address_line1, :address_line2, :city, :state, :pin_code,
             :address_last_updated_at

  attribute :address_cooldown_active
  attribute :next_address_update_date
  attribute :days_until_next_address_update
  attribute :cooldown_message

  def address_cooldown_active
    object.address_cooldown_active?
  end

  def next_address_update_date
    object.next_address_update_date&.strftime("%d %B %Y")
  end

  def days_until_next_address_update
    object.days_until_next_address_update
  end

  def cooldown_message
    if object.address_cooldown_active?
      days = object.days_until_next_address_update
      next_date = object.next_address_update_date&.strftime("%d %B %Y")
      "Your business address was recently updated. You can change it again after #{days} day(s) (on #{next_date})"
    else
      nil
    end
  end
end
