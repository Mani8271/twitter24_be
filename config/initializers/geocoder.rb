Geocoder.configure(
  lookup: :nominatim,
  use_https: true,
  units: :km,
  timeout: 5,

  # ✅ Nominatim requires a proper User-Agent (and ideally contact)
  http_headers: {
    "User-Agent" => "twitter24-be/1.0 (contact: support@twitter24.com)"
  },

  # ✅ Don’t crash your request if geocoding fails
  always_raise: []
)
