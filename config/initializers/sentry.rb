Sentry.init do |config|
  config.dsn = ENV["SENTRY_DSN"]

  # Capture 100% of transactions in development, 10% in production
  config.traces_sample_rate = Rails.env.production? ? 0.1 : 1.0

  config.breadcrumbs_logger = [:active_support_logger, :http_logger]

  # Scrub sensitive parameters from payloads
  config.send_default_pii = false
end
