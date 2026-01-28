module Admin
  class SettingsController < BaseController
    def show
      # Settings page - placeholder for now
    end
    
    def update
      # TODO: Implement settings update
      redirect_to admin_settings_path, notice: 'Settings updated'
    end
  end
end
