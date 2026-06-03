Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    # Allow requests from all Render.com domains
    origins '*'

    # In development, allow localhost
    origins '*' if Rails.env.development?

    resource '*',
      headers: :any,
      methods: [:get, :post, :put, :patch, :delete, :options]
  end
end
