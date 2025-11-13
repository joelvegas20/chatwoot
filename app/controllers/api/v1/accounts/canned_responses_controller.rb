class Api::V1::Accounts::CannedResponsesController < Api::V1::Accounts::BaseController
  before_action :fetch_canned_response, only: [:update, :destroy]

  def index
    responses = canned_responses.map do |cr|
      cr.as_json.merge('short_code' => cr.display_short_code)
    end
    render json: responses
  end

  def create
    @canned_response = Current.account.canned_responses.new(canned_response_params)

    ActiveRecord::Base.transaction do
      @canned_response.save!

      if @canned_response.whatsapp_canned_type?
        channel = Channel::Whatsapp.find_by(account_id: @canned_response.account_id)
        if channel
          service = Whatsapp::TemplateCreationService.new(
            channel: channel,
            canned_response: @canned_response,
            update: false
          )

          result = service.call
          raise StandardError, result[:error_message] if result.is_a?(Hash) && result[:error_message].present?
        end
      end
    end

    render json: @canned_response.as_json.merge('short_code' => @canned_response.display_short_code), status: :ok
  rescue ActiveRecord::RecordInvalid => e
    render json: { errors: [e.message] }, status: :unprocessable_entity
  rescue StandardError => e
    render json: { errors: [e.message] }, status: :unprocessable_entity
  end

  def update
    params[:canned_response][:base_short_code] = params[:canned_response][:short_code] if params[:canned_response][:short_code]
    base_changed = @canned_response.base_short_code != params[:canned_response][:base_short_code]
    @canned_response.update!(canned_response_params)
    @canned_response.skip_sync = true unless base_changed
    render json: @canned_response.as_json.merge('short_code' => @canned_response.display_short_code)
  end

  def destroy
    @canned_response.destroy!
    head :ok
  end

  private

  def fetch_canned_response
    @canned_response = Current.account.canned_responses.find(params[:id])
  end

  def canned_response_params
    params.require(:canned_response).permit(
      :short_code,
      :content,
      :status,
      :canned_type,
      :inbox_id,
      :category
    )
  end

  def canned_responses
    if params[:search]
      Current.account.canned_responses
             .where('short_code ILIKE :search OR content ILIKE :search', search: "%#{params[:search]}%")
             .order_by_search(params[:search])
    else
      Current.account.canned_responses
    end
  end
end
