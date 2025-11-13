class Whatsapp::FacebookApiClient
  BASE_URI = 'https://graph.facebook.com'.freeze

  def initialize(access_token = nil)
    @access_token = access_token
    @api_version = GlobalConfigService.load('WHATSAPP_API_VERSION', 'v22.0')
  end

  def get_templates(waba_id:)
    response = HTTParty.get(
      "#{BASE_URI}/#{@api_version}/#{waba_id}/message_templates",
      headers: request_headers
    )
    handle_response(response, 'Failed to fetch WhatsApp templates')
  end

  def create_template(waba_id:, name:, category:, language:, components:)
    response = HTTParty.post(
      "#{BASE_URI}/#{@api_version}/#{waba_id}/message_templates",
      headers: request_headers,
      body: {
        name: name,
        category: category,
        language: language,
        components: components
      }.to_json
    )

    parsed = JSON.parse(response.body)
    if response.success?
      Rails.logger.info("✅ WhatsApp template created in Meta: #{response['id']}")
    else
      Rails.logger.error("❌ Failed to create WhatsApp template: #{response}")
    end

    parsed
  rescue StandardError => e
    Rails.logger.error("🔥 Error in FacebookApiClient#create_template: #{e.message}")
    { 'error' => { 'message' => e.message } }
  end

  def update_template(waba_id:, template_id:, components:)
    response = HTTParty.post(
      "#{BASE_URI}/#{@api_version}/#{waba_id}/message_templates/#{template_id}",
      headers: request_headers,
      body: { components: components }.to_json
    )

    parsed = JSON.parse(response.body)
    if response.success?
      Rails.logger.info("✅ WhatsApp template updated in Meta: #{template_id}")
    else
      Rails.logger.error("❌ Failed to update WhatsApp template: #{response}")
    end

    parsed
  rescue StandardError => e
    Rails.logger.error("🔥 Error in FacebookApiClient#update_template: #{e.message}")
    { 'error' => { 'message' => e.message } }
  end

  def delete_template(waba_id:, template_name:)
    response = HTTParty.delete(
      "#{BASE_URI}/#{@api_version}/#{waba_id}/message_templates",
      headers: request_headers,
      query: { name: template_name }
    )

    parsed = JSON.parse(response.body)
    if response.success?
      Rails.logger.info("✅ WhatsApp template deleted in Meta: #{template_name}")
    else
      Rails.logger.error("🗑️ Failed to delete WhatsApp template: #{response}")
    end

    parsed
  rescue StandardError => e
    Rails.logger.error("🔥 Error en FacebookApiClient#delete_template: #{e.message}")
    { 'error' => { 'message' => e.message } }
  end

  def exchange_code_for_token(code)
    response = HTTParty.get(
      "#{BASE_URI}/#{@api_version}/oauth/access_token",
      query: {
        client_id: GlobalConfigService.load('WHATSAPP_APP_ID', ''),
        client_secret: GlobalConfigService.load('WHATSAPP_APP_SECRET', ''),
        code: code
      }
    )

    handle_response(response, 'Token exchange failed')
  end

  def fetch_phone_numbers(waba_id)
    response = HTTParty.get(
      "#{BASE_URI}/#{@api_version}/#{waba_id}/phone_numbers",
      query: { access_token: @access_token }
    )

    handle_response(response, 'WABA phone numbers fetch failed')
  end

  def debug_token(input_token)
    response = HTTParty.get(
      "#{BASE_URI}/#{@api_version}/debug_token",
      query: {
        input_token: input_token,
        access_token: build_app_access_token
      }
    )

    handle_response(response, 'Token validation failed')
  end

  def register_phone_number(phone_number_id, pin)
    response = HTTParty.post(
      "#{BASE_URI}/#{@api_version}/#{phone_number_id}/register",
      headers: request_headers,
      body: { messaging_product: 'whatsapp', pin: pin.to_s }.to_json
    )

    handle_response(response, 'Phone registration failed')
  end

  def phone_number_verified?(phone_number_id)
    response = HTTParty.get(
      "#{BASE_URI}/#{@api_version}/#{phone_number_id}",
      headers: request_headers
    )

    data = handle_response(response, 'Phone status check failed')
    data['code_verification_status'] == 'VERIFIED'
  end

  def subscribe_waba_webhook(waba_id, callback_url, verify_token)
    response = HTTParty.post(
      "#{BASE_URI}/#{@api_version}/#{waba_id}/subscribed_apps",
      headers: request_headers,
      body: {
        override_callback_uri: callback_url,
        verify_token: verify_token
      }.to_json
    )

    handle_response(response, 'Webhook subscription failed')
  end

  def unsubscribe_waba_webhook(waba_id)
    response = HTTParty.delete(
      "#{BASE_URI}/#{@api_version}/#{waba_id}/subscribed_apps",
      headers: request_headers
    )

    handle_response(response, 'Webhook unsubscription failed')
  end

  private

  def request_headers
    {
      'Authorization' => "Bearer #{@access_token}",
      'Content-Type' => 'application/json'
    }
  end

  def build_app_access_token
    app_id = GlobalConfigService.load('WHATSAPP_APP_ID', '')
    app_secret = GlobalConfigService.load('WHATSAPP_APP_SECRET', '')
    "#{app_id}|#{app_secret}"
  end

  def handle_response(response, error_message)
    raise "#{error_message}: #{response.body}" unless response.success?

    response.parsed_response
  end
end
