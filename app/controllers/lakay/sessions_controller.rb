module Lakay
  class SessionsController < ApplicationController
    layout "admin"

    # GET /lakay/login
    def new
      redirect_to lakay_root_path if admin_signed_in?
    end

    # POST /lakay/login
    def create
      admin = Administrator.find_by(name: params[:name])

      if admin&.authenticate(params[:password])
        session[:admin_id] = admin.id
        redirect_to lakay_root_path, notice: t("devise.sessions.signed_in")
      else
        flash.now[:alert] = t("devise.failure.invalid", authentication_keys: "name")
        render :new, status: :unprocessable_entity
      end
    end

    # DELETE /lakay/logout
    def destroy
      session.delete(:admin_id)
      redirect_to lakay_login_path, notice: t("devise.sessions.signed_out")
    end
  end
end
