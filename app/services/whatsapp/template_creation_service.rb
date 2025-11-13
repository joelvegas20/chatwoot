class Whatsapp::TemplateCreationService
  def initialize(channel:, canned_response:, update: false)
    @channel = channel
    @canned_response = canned_response
    @update = update
  end

  def call
    return unless whatsapp_canned_type?

    waba_id = @channel.provider_config['business_account_id']
    access_token = @channel.provider_config['api_key']
    client = Whatsapp::FacebookApiClient.new(access_token)

    template_name = @canned_response.short_code.parameterize.underscore

    exists = template_exists_or_pending?(client, waba_id, template_name)

    if exists && !@update
      Rails.logger.warn("⚠️ Template #{template_name} ya existe o está en eliminación, se marca como rechazado.")
      @canned_response.update(status: 'rejected')
      return
    end

    if exists && @update
      # For update, since short_code same, don't delete, just try to create new, which Meta takes as update
      Rails.logger.info("⚠️ Template #{template_name} exists, attempting to 'update' by creating new.")
    end

    response = client.create_template(
      waba_id: waba_id,
      name: template_name,
      category: 'MARKETING',
      language: 'es',
      components: [
        {
          type: 'BODY',
          text: @canned_response.content
        }
      ]
    )

    if response['error']
      Rails.logger.error("❌ Failed to create WhatsApp template: #{response}")
      @canned_response.update(status: 'rejected')
      error_msg = response.dig('error', 'error_user_msg') ||
                  response.dig('error', 'message') ||
                  'Error desconocido al crear el template en Meta.'
      raise StandardError, error_msg
    else
      Rails.logger.info("✅ WhatsApp template created in Meta: #{response['id']}")
      @canned_response.update(status: 'pending', template_id: response['id'])
    end
  rescue StandardError => e
    Rails.logger.error("🔥 Error en TemplateCreationService: #{e.message}")
    @canned_response.update(status: 'rejected')
    { error_message: e.message }
  end

  private

  def whatsapp_canned_type?
    @canned_response.canned_type == 'whatsapp'
  end

  def template_exists_or_pending?(client, waba_id, template_name)
    templates = client.get_templates(waba_id: waba_id)
    found = templates['data']&.find { |t| t['name'] == template_name }

    return false unless found

    return %w[DELETING PENDING_DELETION].include?(found['status']) || found['status'] == 'APPROVED' || found['status'] == 'PENDING'
  rescue StandardError => e
    Rails.logger.error("⚠️ Error verificando templates: #{e.message}")
    false
  end
end
