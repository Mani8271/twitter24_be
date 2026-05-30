# Be sure to restart your server when you modify this file.

# Avoid CORS issues when API is called from the frontend app.
# Handle Cross-Origin Resource Sharing (CORS) in order to accept cross-origin AJAX requests.

# Read more: https://github.com/cyu/rack-cors

Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    # In production, set ALLOWED_ORIGINS to your frontend domain(s) comma-separated.
    # e.g. ALLOWED_ORIGINS=https://twitter24.vercel.app,https://www.twitter24.com
    # Falls back to localhost only when the env var is not set (development).
    allowed = ENV.fetch("ALLOWED_ORIGINS", "http://localhost:3000")
                 .split(",")
                 .map(&:strip)
                 .reject(&:blank?)

    origins(*allowed)

    resource '*',
      headers: :any,
      methods: [:get, :post, :put, :patch, :delete, :options, :head],
      credentials: false
  end
end