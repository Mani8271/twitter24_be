Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    # Allow requests from all Render.com domains
    origins 'twitter24-htj4.onrender.com', 'twitter24-be.onrender.com'

    # In development, allow localhost
    origins 'localhost:3000', 'localhost:3001' if Rails.env.development?

    resource '*',
      headers: :any,
      methods: [:get, :post, :put, :patch, :delete, :options]
  end
end
