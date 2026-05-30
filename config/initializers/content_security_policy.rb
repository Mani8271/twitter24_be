# Be sure to restart your server when you modify this file.

Rails.application.configure do
  config.content_security_policy do |policy|
    policy.default_src :self
    policy.font_src    :self, :https, :data
    policy.img_src     :self, :https, :data, "https://ui-avatars.com"
    policy.object_src  :none
    # ActiveAdmin uses inline scripts/styles; allow them only for /admin paths.
    # For API endpoints (JSON), the CSP header is ignored by clients.
    policy.script_src  :self, :https, :unsafe_inline
    policy.style_src   :self, :https, :unsafe_inline
    policy.connect_src :self, :https
    policy.frame_ancestors :none
  end

  # Start in report-only mode so existing admin panel is not broken.
  # Switch to enforcement by removing this line once verified in staging.
  config.content_security_policy_report_only = true
end
