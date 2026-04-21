require "net/http"
require "json"

# PhonePe Checkout v2 — OAuth-based API
class PhonePeService
  DEFAULT_TOKEN_URLS = {
    "UAT"        => "https://api-preprod.phonepe.com/apis/pg/v1/oauth/token",
    "PRODUCTION" => "https://api.phonepe.com/apis/pg/v1/oauth/token"
  }.freeze

  DEFAULT_CHECKOUT_BASE_URLS = {
    "UAT"        => "https://api-preprod.phonepe.com/apis/pg",
    "PRODUCTION" => "https://api.phonepe.com/apis/pg"
  }.freeze

  def initialize
    @client_id      = ENV.fetch("PHONEPE_CLIENT_ID")
    @client_secret  = ENV.fetch("PHONEPE_CLIENT_SECRET")
    @client_version = ENV.fetch("PHONEPE_CLIENT_VERSION", "1")
    @env            = ENV.fetch("PHONEPE_ENV", "UAT").upcase
    @base_url       = ENV.fetch("PHONEPE_CHECKOUT_URL", DEFAULT_CHECKOUT_BASE_URLS.fetch(@env))
    @token_url      = ENV.fetch("PHONEPE_TOKEN_URL", DEFAULT_TOKEN_URLS.fetch(@env))
  end

  def initiate_payment(merchant_order_id:, amount_in_paise:, redirect_url:)
    token = fetch_access_token
    return { success: false, message: token[:error] } if token[:error]

    payload = {
      merchantOrderId: merchant_order_id,
      amount:          amount_in_paise,
      expireAfter:     1200,
      paymentFlow:     {
        type:         "PG_CHECKOUT",
        merchantUrls: { redirectUrl: redirect_url }
      }
    }

    response = post_request("/checkout/v2/pay", payload, token[:access_token])

    Rails.logger.info "[PhonePe] initiate status=#{response.code} body=#{response.body}"

    body = parse_json(response.body)

    if response.code.to_i == 200 && body["redirectUrl"].present?
      { success: true, redirect_url: body["redirectUrl"], order_id: body["orderId"] }
    else
      { success: false, message: body["message"] || body.dig("error", "message") || "Payment initiation failed" }
    end
  end

  def check_status(merchant_order_id)
    token = fetch_access_token
    return { success: false, state: "FAILED", message: token[:error] } if token[:error]

    response = get_request("/checkout/v2/order/#{merchant_order_id}/status", token[:access_token])

    Rails.logger.info "[PhonePe] status check status=#{response.code} body=#{response.body}"

    body = parse_json(response.body)

    if response.code.to_i == 200
      { success: true, state: body["state"], order_id: body["orderId"], data: body }
    else
      { success: false, state: "PENDING", message: body["message"] || "Status check failed" }
    end
  end

  private

  def fetch_access_token
    Rails.logger.info "[PhonePe] fetching token from #{@token_url}"

    # Try 1: Basic Auth + form body (standard OAuth 2.0 client credentials)
    response = token_with_basic_auth
    Rails.logger.info "[PhonePe] token(basic_auth) status=#{response.code} body=#{response.body}"
    body = parse_json(response.body)
    return { access_token: body["access_token"] } if response.code.to_i == 200 && body["access_token"].present?

    # Try 2: JSON body with client creds (PhonePe proprietary)
    response = token_with_json_body
    Rails.logger.info "[PhonePe] token(json_body) status=#{response.code} body=#{response.body}"
    body = parse_json(response.body)
    return { access_token: body["access_token"] } if response.code.to_i == 200 && body["access_token"].present?

    { error: body["message"] || "Failed to get PhonePe token" }
  end

  def token_with_basic_auth
    uri  = URI(@token_url)
    http = build_http(uri)

    req = Net::HTTP::Post.new(uri.request_uri)
    req["Content-Type"] = "application/x-www-form-urlencoded"
    req["Accept"]       = "application/json"
    req.basic_auth(@client_id, @client_secret)
    req.body = URI.encode_www_form(
      grant_type:     "client_credentials",
      client_version: @client_version
    )

    http.request(req)
  end

  def token_with_json_body
    uri  = URI(@token_url)
    http = build_http(uri)

    req = Net::HTTP::Post.new(uri.request_uri)
    req["Content-Type"] = "application/json"
    req["Accept"]       = "application/json"
    req.body = {
      client_id:      @client_id,
      client_secret:  @client_secret,
      grant_type:     "client_credentials",
      client_version: @client_version
    }.to_json

    http.request(req)
  end

  def post_request(path, body, access_token)
    uri  = URI("#{@base_url}#{path}")
    http = build_http(uri)

    req = Net::HTTP::Post.new(uri.path)
    req["Content-Type"]  = "application/json"
    req["Accept"]        = "application/json"
    req["Authorization"] = "O-Bearer #{access_token}" if access_token
    req.body = body.to_json

    http.request(req)
  end

def get_request(path, access_token)
    uri  = URI("#{@base_url}#{path}")
    http = build_http(uri)

    req = Net::HTTP::Get.new(uri.path)
    req["Content-Type"]  = "application/json"
    req["Accept"]        = "application/json"
    req["Authorization"] = "O-Bearer #{access_token}"

    http.request(req)
  end

  def build_http(uri)
    http              = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl      = true
    http.open_timeout = 10
    http.read_timeout = 30
    http
  end

  def parse_json(body)
    JSON.parse(body)
  rescue JSON::ParserError
    {}
  end
end
