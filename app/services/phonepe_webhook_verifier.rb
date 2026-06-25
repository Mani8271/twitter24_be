require "openssl"

# Verifies PhonePe webhook signatures and ensures webhook authenticity.
#
# PhonePe sends webhooks with X-Verify header containing a base64-encoded HMAC-SHA256
# signature. This service verifies that the signature matches the webhook payload,
# ensuring the webhook was not tampered with and came from PhonePe.
#
# References:
# - PhonePe Checkout v2 Webhook docs: https://phonepe.gitbook.io/
class PhonePeWebhookVerifier
  ALGORITHM = "SHA256".freeze
  ENCODING = "base64".freeze

  # PhonePe sends X-Verify header as: base64(HMAC-SHA256(body, salt + API_KEY))
  # where salt is part of the X-Verify header, separated by ###
  def initialize
    @api_key = ENV.fetch("PHONEPE_API_KEY", "")
    @merchant_id = ENV.fetch("PHONEPE_MERCHANT_ID", "")
  end

  # Verify webhook signature from PhonePe
  #
  # @param x_verify_header [String] The X-Verify header from PhonePe request
  # @param raw_body [String] The raw request body (not parsed JSON)
  # @return [Hash] { valid: true/false, error: nil/error_message, request_id: request_id }
  def verify(x_verify_header:, raw_body:)
    # Check if verification is disabled (development/testing only)
    if ENV["PHONEPE_WEBHOOK_VERIFY_DISABLED"] == "true"
      Rails.logger.warn "[PhonePeWebhookVerifier] Signature verification DISABLED (dev mode)"
      return { valid: true, error: nil, skip_reason: "verification_disabled" }
    end

    # Validate inputs
    unless x_verify_header.present? && raw_body.present?
      return { valid: false, error: "Missing X-Verify header or body" }
    end

    # Parse X-Verify header: base64_signature###salt
    signature_parts = x_verify_header.split("###")
    if signature_parts.size != 2
      return { valid: false, error: "Invalid X-Verify header format" }
    end

    received_signature_b64 = signature_parts[0]
    salt = signature_parts[1]

    # Compute expected signature
    expected_signature = compute_signature(raw_body, salt)

    # Compare signatures using constant-time comparison (prevent timing attacks)
    if ActiveSupport::SecurityUtils.secure_compare(expected_signature, received_signature_b64)
      Rails.logger.info "[PhonePeWebhookVerifier] ✓ Signature verified successfully"
      { valid: true, error: nil, signature_hash: Digest::SHA256.hexdigest(received_signature_b64) }
    else
      Rails.logger.warn "[PhonePeWebhookVerifier] ✗ Signature mismatch!"
      Rails.logger.debug "[PhonePeWebhookVerifier] Expected: #{expected_signature[0..20]}... Got: #{received_signature_b64[0..20]}..."
      { valid: false, error: "Signature verification failed" }
    end
  rescue StandardError => e
    Rails.logger.error "[PhonePeWebhookVerifier] Exception: #{e.class} #{e.message}"
    { valid: false, error: "Signature verification error: #{e.message}" }
  end

  private

  # Compute HMAC-SHA256 signature for verification
  # Format: base64(HMAC-SHA256(body, salt + api_key))
  def compute_signature(body, salt)
    key = "#{salt}#{@api_key}"
    hmac = OpenSSL::HMAC.digest("SHA256", key, body)
    Base64.strict_encode64(hmac)
  end
end
