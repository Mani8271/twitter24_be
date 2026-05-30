class Rack::Attack
  # ── Throttle auth endpoints by IP ────────────────────────────────────────────

  # Signup: 10 attempts per hour per IP
  throttle("auth/signup", limit: 10, period: 1.hour) do |req|
    req.ip if req.path == "/signup" && req.post?
  end

  # Signin: 20 attempts per hour per IP
  throttle("auth/signin", limit: 20, period: 1.hour) do |req|
    req.ip if req.path == "/signin" && req.post?
  end

  # OTP send: 5 per hour per IP (per-user daily limit handled in controller)
  throttle("auth/send_otp", limit: 5, period: 1.hour) do |req|
    req.ip if req.path == "/send_otp" && req.post?
  end

  # OTP verify: 10 attempts per 30 minutes per IP (brute-force guard)
  throttle("auth/verify_otp", limit: 10, period: 30.minutes) do |req|
    req.ip if req.path == "/verify_otp" && req.post?
  end

  # Password reset: 5 attempts per hour per IP
  throttle("auth/reset_password", limit: 5, period: 1.hour) do |req|
    req.ip if req.path == "/reset_password" && req.post?
  end

  # ── General API throttle ─────────────────────────────────────────────────────
  # 300 requests per minute per IP — generous for a mobile/web app
  throttle("api/general", limit: 300, period: 1.minute) do |req|
    req.ip unless req.path.start_with?("/admin")
  end

  # ── Throttled response ────────────────────────────────────────────────────────
  self.throttled_responder = lambda do |env|
    [
      429,
      { "Content-Type" => "application/json" },
      [{ error: "Too many requests. Please try again later." }.to_json]
    ]
  end
end
