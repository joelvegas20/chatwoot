class Whatsapp::TemplateDeletionService
  pattr_initialize [:channel!, :canned_response!, { template_name: nil }]

  GRAPH_API_VERSION = 'v22.0'.freeze

  def call
    facebook_client = Whatsapp::FacebookApiClient.new(channel.provider_config['api_key'])
    waba_id = channel.provider_config['business_account_id']

    template_name = @template_name || canned_response.short_code.parameterize.underscore

    response = facebook_client.delete_template(
      waba_id: waba_id,
      template_name: template_name
    )

    if response['success']
      Rails.logger.info("✅ Template Deleted #{template_name} successfully.")
    else
      Rails.logger.warn("⚠️ Failed to delete template #{template_name}: #{response}")
    end

    response
  rescue StandardError => e
    Rails.logger.error("🔥 Error deleting WhatsApp template: #{e.message}")
    nil
  end
end
