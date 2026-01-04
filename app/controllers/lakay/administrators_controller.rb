module Lakay
  class AdministratorsController < BaseController
    before_action :authorize_super_admin!
    before_action :set_administrator, only: [:show, :edit, :update, :destroy]

    def index
      @administrators = Administrator.order(:name)
    end

    def show
    end

    def new
      @administrator = Administrator.new
    end

    def create
      @administrator = Administrator.new(administrator_params)

      if @administrator.save
        redirect_to lakay_administrators_path, notice: t("flash.created", resource: "Administrator")
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      update_params = administrator_params
      update_params = update_params.except(:password, :password_confirmation) if update_params[:password].blank?

      if @administrator.update(update_params)
        redirect_to lakay_administrators_path, notice: t("flash.updated", resource: "Administrator")
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      if @administrator == current_admin
        redirect_to lakay_administrators_path, alert: "You cannot delete yourself."
      else
        @administrator.destroy
        redirect_to lakay_administrators_path, notice: t("flash.deleted", resource: "Administrator")
      end
    end

    private

    def set_administrator
      @administrator = Administrator.find(params[:id])
    end

    def administrator_params
      params.require(:administrator).permit(:name, :password, :password_confirmation, :role)
    end
  end
end
