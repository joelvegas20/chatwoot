class Api::V1::Accounts::SidebarAppsController < Api::V1::Accounts::BaseController
  before_action :fetch_sidebar_apps, except: [:create]
  before_action :fetch_sidebar_app, only: [:show, :update, :destroy]

  def index
    @sidebar_apps = fetch_sidebar_apps
    render json: @sidebar_apps
  end

  def show
    @sidebar_app = fetch_sidebar_app
    render json: @sidebar_app
  end

  def create
    Rails.logger.info("SidebarAppsController#create - Params: #{params.inspect}")
    Rails.logger.info("SidebarAppsController#create - Permitted payload: #{permitted_payload.inspect}")

    @sidebar_app = Current.account.sidebar_apps.create!(
      permitted_payload.merge(user_id: Current.user.id)
    )

    Rails.logger.info("SidebarAppsController#create - Created sidebar app: #{@sidebar_app.inspect}")
    render json: @sidebar_app, status: :created
  rescue StandardError => e
    Rails.logger.error("SidebarAppsController#create - Error: #{e.message}")
    Rails.logger.error("SidebarAppsController#create - Backtrace: #{e.backtrace.join("\n")}")
    raise e
  end

  def update
    @sidebar_app.update!(permitted_payload)
    render json: @sidebar_app
  end

  def destroy
    @sidebar_app.destroy!
    head :no_content
  end

  private

  def fetch_sidebar_apps
    @sidebar_apps = Current.account.sidebar_apps
  end

  def fetch_sidebar_app
    @sidebar_app = @sidebar_apps.find(permitted_params[:id])
  end

  def permitted_params
    params.permit(:id)
  end

  def permitted_payload
    params.require(:sidebar_app).permit(:title, :icon, :visible, content: [[:type, :url]])
  end
end
