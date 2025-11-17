require 'sendgrid-ruby'
require 'erb'

puts '=== SENDGRID INITIALIZER LOADED ==='
puts "API Key present: #{ENV['SENDGRID_API_KEY'] ? 'YES' : 'NO'}"

# Custom ActionMailer delivery method for SendGrid
class SendgridApiDelivery
  def initialize(_settings = {})
    @api_key = ENV.fetch('SENDGRID_API_KEY', nil)
    raise 'SENDGRID_API_KEY not configured' unless @api_key.present?

    @sendgrid = SendGrid::API.new(api_key: @api_key)
  end

  def deliver!(mail)
    puts '=== SENDGRID DELIVER! METHOD CALLED ==='
    puts "API Key: #{@api_key ? 'PRESENT' : 'MISSING'}"

    # Create email object
    mail_object = SendGrid::Mail.new

    # Set from
    from_email = SendGrid::Email.new(email: mail.from.first, name: mail[:from].display_names.first)
    mail_object.from = from_email

    # Create personalization for recipients
    personalization = SendGrid::Personalization.new

    # Add to recipients
    mail.to.each do |email|
      personalization.add_to(SendGrid::Email.new(email: email))
    end

    # Add CC if present
    if mail.cc
      mail.cc.each do |email|
        personalization.add_cc(SendGrid::Email.new(email: email))
      end
    end

    # Add BCC if present
    if mail.bcc
      mail.bcc.each do |email|
        personalization.add_bcc(SendGrid::Email.new(email: email))
      end
    end

    # Set subject
    personalization.subject = mail.subject
    mail_object.add_personalization(personalization)

    # Disable SendGrid tracking to prevent HTML corruption
    tracking_settings = SendGrid::TrackingSettings.new
    tracking_settings.click_tracking = SendGrid::ClickTracking.new(enable: false)
    tracking_settings.open_tracking = SendGrid::OpenTracking.new(enable: false)
    mail_object.tracking_settings = tracking_settings

    # Set content - ORDER MATTERS: text/plain must come first, then text/html
    # Handle different email formats (multipart vs single part)
    if mail.multipart?
      content_text = mail.text_part&.body&.to_s || mail.body.to_s
      content_html = mail.html_part&.body&.to_s
    elsif mail.content_type&.include?('text/html')
      # Single part email - check content type
      content_text = mail.body.to_s
      content_html = mail.body.to_s
    # HTML email - render if needed
    else
      # Plain text email
      content_text = mail.body.to_s
      content_html = nil
    end

    # If HTML content contains ERB tags, it means it wasn't rendered properly
    # This can happen with Devise emails - let's try to render it
    if content_html && content_html.include?('<%')
      puts '⚠️  Detected unrendered ERB in HTML content, attempting to render...'
      begin
        # Create a simple ERB renderer for basic variables
        erb_template = ERB.new(content_html)
        # Create a binding with basic Rails environment variables
        app_name = ENV.fetch('APP_NAME', 'Chatwoot')
        binding_context = binding
        binding_context.local_variable_set(:app_name, app_name)
        content_html = erb_template.result(binding_context)
        puts '✅ ERB rendered successfully'
      rescue StandardError => e
        puts "❌ ERB rendering failed: #{e.message}"
      end
    end

    # Add text content FIRST (required by SendGrid)
    mail_object.add_content(SendGrid::Content.new(
                              type: 'text/plain',
                              value: content_text
                            ))

    # Add HTML content SECOND (if present)
    if content_html
      mail_object.add_content(SendGrid::Content.new(
                                type: 'text/html',
                                value: content_html
                              ))
    end

    # Set reply-to if present
    mail_object.reply_to = SendGrid::Email.new(email: mail.reply_to.first) if mail.reply_to

    # Send email
    begin
      response = @sendgrid.client.mail._('send').post(request_body: mail_object.to_json)

      unless response.status_code.to_i >= 200 && response.status_code.to_i < 300
        raise "SendGrid API error: #{response.status_code} - #{response.body}"
      end

      puts '✅ Email sent successfully via SendGrid'

    rescue StandardError => e
      puts "❌ SendGrid delivery error: #{e.message}"
      raise e
    end
  end
end

# Register the delivery method
ActionMailer::Base.add_delivery_method :sendgrid_api, SendgridApiDelivery

# Configure ActionMailer to use SendGrid if specified
if ENV['EMAIL_DELIVERY_METHOD'] == 'sendgrid_api'
  puts 'Using SendGrid API for email delivery'
  ActionMailer::Base.delivery_method = :sendgrid_api
end
