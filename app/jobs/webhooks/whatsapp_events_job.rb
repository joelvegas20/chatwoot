class Webhooks::WhatsappEventsJob < ApplicationJob
  queue_as :low

  def perform(params)
    entry = params['entry']&.first
    return unless entry

    changes = entry['changes'] || []
    changes.each do |change|
      value = change['value']
      next unless value.present? && value['event'].present?

      event = value['event']
      template_name = value['message_template_name']
      template_id = value['message_template_id']

      normalized_name = template_name.to_s.downcase.strip.gsub(/[^a-z0-9_]/, '')

      canned_response = CannedResponse.find_by(template_id: template_id) ||
                        CannedResponse.find_by('REPLACE(REPLACE(short_code, "/", ""), "-", "_") = ?', normalized_name)

      if canned_response
        case event
        when 'APPROVED'
          canned_response.update(status: 'approved')
          Rails.logger.info("✅ Template approved in Meta: #{template_name} -> updated to 'approved'")
        when 'REJECTED'
          canned_response.update(status: 'rejected')
          Rails.logger.info("❌ Template rejected in Meta: #{template_name} -> updated to 'rejected'")
        when 'PENDING'
          canned_response.update(status: 'pending')
          Rails.logger.info("🕓 Template pending in Meta: #{template_name} -> updated to 'pending'")
        else
          Rails.logger.warn("⚠️ Unrecognized event type received: #{event}")
        end
      else
        Rails.logger.warn("⚠️ No CannedResponse found for template #{template_name} (ID: #{template_id})")
      end
    end
  rescue StandardError => e
    Rails.logger.error("🔥 Error processing WhatsApp webhook: #{e.message}")
  end

  private

  def channel_is_inactive?(channel)
    return true if channel.blank?
    return true if channel.reauthorization_required?
    return true unless channel.account.active?

    false
  end

  def find_channel_by_url_param(params)
    return unless params[:phone_number]

    Channel::Whatsapp.find_by(phone_number: params[:phone_number])
  end

  def find_channel_from_whatsapp_business_payload(params)
    # for the case where facebook cloud api support multiple numbers for a single app
    # https://github.com/chatwoot/chatwoot/issues/4712#issuecomment-1173838350
    # we will give priority to the phone_number in the payload
    return get_channel_from_wb_payload(params) if params[:object] == 'whatsapp_business_account'

    find_channel_by_url_param(params)
  end

  def get_channel_from_wb_payload(wb_params)
    phone_number = "+#{wb_params[:entry].first[:changes].first.dig(:value, :metadata, :display_phone_number)}"
    phone_number_id = wb_params[:entry].first[:changes].first.dig(:value, :metadata, :phone_number_id)
    channel = Channel::Whatsapp.find_by(phone_number: phone_number)
    # validate to ensure the phone number id matches the whatsapp channel
    return channel if channel && channel.provider_config['phone_number_id'] == phone_number_id
  end
end
