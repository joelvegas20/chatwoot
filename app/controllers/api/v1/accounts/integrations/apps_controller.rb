class Api::V1::Accounts::Integrations::AppsController < Api::V1::Accounts::BaseController
  before_action :fetch_apps, only: [:index]
  before_action :fetch_app, only: [:show]

  def index
    render json: { payload: @apps.map { |app| app_to_json(app) } }
  end

  def show
    render json: { payload: app_to_json(@app) }
  end

  private

  def fetch_apps
    @apps = Integrations::App.all.select { |app| app.active?(Current.account) }
  end

  def fetch_app
    @app = Integrations::App.find(id: params[:id])
  end

  def app_to_json(app)
    {
      id: app.id,
      name: app.name,
      description: app.description,
      logo: app.logo,
      enabled: app.enabled?(Current.account)
    }
  end
end
