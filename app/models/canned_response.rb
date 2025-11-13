# == Schema Information
#
# Table name: canned_responses
#
#  id              :integer          not null, primary key
#  base_short_code :string
#  canned_type     :string           default("generic"), not null
#  category        :string           default("general"), not null
#  content         :text
#  short_code      :string
#  status          :string           default("active"), not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  account_id      :integer          not null
#  inbox_id        :bigint
#  template_id     :string
#
# Indexes
#
#  index_canned_responses_on_inbox_id  (inbox_id)
#
# Foreign Keys
#
#  fk_rails_...  (inbox_id => inboxes.id)
#

class CannedResponse < ApplicationRecord
  attr_accessor :skip_sync

  belongs_to :account
  belongs_to :inbox, optional: true
  before_validation :append_timestamp_to_short_code, on: :create
  before_save :update_short_code_for_whatsapp
  after_destroy :delete_meta_template_if_whatsapp
  after_commit :sync_meta_template_with_whatsapp, on: :update, if: :whatsapp_canned_type?

  enum status: {
    active: 'active',
    pending: 'pending',
    approved: 'approved',
    rejected: 'rejected',
    deleted: 'deleted'
  }, _suffix: true

  enum canned_type: {
    generic: 'generic',
    whatsapp: 'whatsapp',
    api: 'api',
    telegram: 'telegram',
    line: 'line',
    messenger: 'messenger',
    twitter: 'twitter',
    email: 'email',
    sms: 'sms',
    website: 'website'
  }, _suffix: true

  validates :content, :account, :status, :canned_type, presence: true
  validates :base_short_code, presence: true, if: :whatsapp_canned_type?
  validates :base_short_code, uniqueness: { scope: :account_id }, if: :whatsapp_canned_type?
  validates :short_code, uniqueness: { scope: :account_id }

  scope :order_by_search, lambda { |search|
    short_code_starts_with = sanitize_sql_array(['WHEN short_code ILIKE ? THEN 1', "#{search}%"])
    short_code_like = sanitize_sql_array(['WHEN short_code ILIKE ? THEN 0.5', "%#{search}%"])
    content_like = sanitize_sql_array(['WHEN content ILIKE ? THEN 0.2', "%#{search}%"])
    order_clause = "CASE #{short_code_starts_with} #{short_code_like} #{content_like} ELSE 0 END"
    order(Arel.sql(order_clause) => :desc)
  }

  def display_short_code
    base_short_code || short_code
  end

  private

  def append_timestamp_to_short_code
    return unless canned_type == 'whatsapp'

    self.base_short_code = short_code
    timestamp = Time.current.to_i
    base_code = short_code.to_s.gsub(/[^a-zA-Z0-9_-]/, '')
    self.short_code = "#{base_code}-#{timestamp}"
  end

  def update_short_code_for_whatsapp
    return unless whatsapp_canned_type? && base_short_code_changed?

    timestamp = Time.current.to_i
    base_code = base_short_code.to_s.gsub(/[^a-zA-Z0-9_-]/, '')
    self.short_code = "#{base_code}-#{timestamp}"
  end

  def create_meta_template_if_whatsapp
    return unless whatsapp_canned_type?

    channel = Channel::Whatsapp.find_by(account_id: account_id)
    return unless channel

    update_column(:status, 'pending')

    Whatsapp::TemplateCreationService.new(
      channel: channel,
      canned_response: self
    ).call
  end

  def sync_meta_template_with_whatsapp
    return if @skip_sync
    return if saved_change_to_status? && previous_changes.keys == ['status']

    old_inbox_id = saved_change_to_inbox_id&.first
    new_inbox_id = saved_change_to_inbox_id&.last
    base_changed = saved_change_to_base_short_code?
    content_changed = saved_change_to_content?
    if old_inbox_id != new_inbox_id || base_changed
      handle_name_change
    elsif content_changed
      handle_content_change
    end
  end

  def handle_name_change
    # Delete old template
    old_short_code = saved_change_to_short_code&.first || saved_change_to_base_short_code&.first
    if old_short_code
      old_template_name = old_short_code.parameterize.underscore
      channel = Channel::Whatsapp.find_by(account_id: account_id)
      Whatsapp::TemplateDeletionService.new(channel: channel, canned_response: self, template_name: old_template_name).call if channel
    end

    # Create new template
    channel = Channel::Whatsapp.find_by(account_id: account_id)
    return unless channel

    update_column(:status, 'pending')
    Whatsapp::TemplateCreationService.new(channel: channel, canned_response: self).call
  end

  def handle_content_change
    channel = Channel::Whatsapp.find_by(account_id: account_id)
    return Rails.logger.warn("⚠️ Whatsapp channel not found for CannedResponse ID: #{id}") unless channel

    # Check if template is approved before updating
    templates = Whatsapp::FacebookApiClient.new(channel.provider_config['api_key']).get_templates(waba_id: channel.provider_config['business_account_id'])
    template = templates['data']&.find { |t| t['name'] == short_code.parameterize.underscore }
    if template && template['status'] == 'APPROVED'
      Whatsapp::TemplateDeletionService.new(channel: channel, canned_response: self).call
      update_column(:status, 'pending')
      Whatsapp::TemplateCreationService.new(channel: channel, canned_response: self).call
    else
      Rails.logger.info("⚠️ Template not approved or not found, skipping content update for CannedResponse ID: #{id}")
    end
  end

  def delete_meta_template_if_whatsapp
    return unless whatsapp_canned_type?

    channel = Channel::Whatsapp.find_by(account_id: account_id)
    return unless channel

    Whatsapp::TemplateDeletionService.new(
      channel: channel,
      canned_response: self
    ).call
  end
end
