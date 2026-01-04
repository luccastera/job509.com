class ReferralsController < ApplicationController
  before_action :authenticate_user!
  before_action :require_job_seeker!
  before_action :set_resume
  before_action :set_referral, only: [:update, :destroy]

  def create
    @referral = @resume.referrals.build(referral_params)

    if @referral.save
      redirect_to edit_resume_path, notice: t("flash.created", resource: t("activerecord.models.referral"))
    else
      redirect_to edit_resume_path, alert: @referral.errors.full_messages.join(", ")
    end
  end

  def update
    if @referral.update(referral_params)
      redirect_to edit_resume_path, notice: t("flash.updated", resource: t("activerecord.models.referral"))
    else
      redirect_to edit_resume_path, alert: @referral.errors.full_messages.join(", ")
    end
  end

  def destroy
    @referral.destroy
    redirect_to edit_resume_path, notice: t("flash.deleted", resource: t("activerecord.models.referral"))
  end

  private

  def set_resume
    @resume = current_user.resume
    redirect_to edit_resume_path, alert: "Please create your resume first." unless @resume
  end

  def set_referral
    @referral = @resume.referrals.find(params[:id])
  end

  def referral_params
    params.require(:referral).permit(:firstname, :lastname, :phone, :email, :relationship)
  end
end
