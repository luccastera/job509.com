module Lakay
  class BaseController < ApplicationController
    before_action :authenticate_admin!
    layout "admin"

    private

    def authenticate_admin!
      unless admin_signed_in?
        redirect_to lakay_login_path, alert: t("flash.login_required")
      end
    end
  end
end
