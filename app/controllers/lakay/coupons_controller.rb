module Lakay
  class CouponsController < BaseController
    before_action :set_coupon, only: [:show, :edit, :update, :destroy]

    def index
      @coupons = Coupon.order(created_at: :desc)
    end

    def show
    end

    def new
      @coupon = Coupon.new
    end

    def create
      @coupon = Coupon.new(coupon_params)
      @coupon.administrator = current_admin

      if @coupon.save
        redirect_to lakay_coupons_path, notice: t("flash.created", resource: "Coupon")
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      if @coupon.update(coupon_params)
        redirect_to lakay_coupons_path, notice: t("flash.updated", resource: "Coupon")
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @coupon.destroy
      redirect_to lakay_coupons_path, notice: t("flash.deleted", resource: "Coupon")
    end

    private

    def set_coupon
      @coupon = Coupon.find(params[:id])
    end

    def coupon_params
      params.require(:coupon).permit(:code, :value, :comment)
    end
  end
end
