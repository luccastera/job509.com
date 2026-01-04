class ApplicsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_applic, only: [:show, :destroy, :star, :unstar, :hide, :unhide, :cover_letter, :print]
  before_action :authorize_applic_access!

  # GET /applics
  def index
    if current_user.employer?
      # Employer sees applications to their jobs
      @applics = Applic.joins(:job).where(jobs: { user_id: current_user.id }).includes(:user, :job).recent
    else
      # Job seeker sees their own applications
      @applics = current_user.applics.includes(:job).recent
    end

    @pagy, @applics = pagy(@applics, limit: 20)
  end

  # GET /applics/:id
  def show
    @resume = @applic.user.resume
  end

  # DELETE /applics/:id
  def destroy
    @applic.destroy
    redirect_to applics_path, notice: t("flash.deleted", resource: t("activerecord.models.applic"))
  end

  # PATCH /applics/:id/star
  def star
    @applic.update(star: true)
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to applics_path }
    end
  end

  # PATCH /applics/:id/unstar
  def unstar
    @applic.update(star: false)
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to applics_path }
    end
  end

  # PATCH /applics/:id/hide
  def hide
    @applic.update(hidden: true)
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to applics_path }
    end
  end

  # PATCH /applics/:id/unhide
  def unhide
    @applic.update(hidden: false)
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to applics_path }
    end
  end

  # GET /applics/:id/cover_letter
  def cover_letter
    render layout: false
  end

  # GET /applics/:id/print
  def print
    @resume = @applic.user.resume
    render layout: "print"
  end

  private

  def set_applic
    @applic = Applic.find(params[:id])
  end

  def authorize_applic_access!
    # Job seeker can only see their own applications
    # Employer can only see applications to their jobs
    if current_user.job_seeker?
      unless @applic.user == current_user
        redirect_to applics_path, alert: t("flash.not_authorized")
      end
    elsif current_user.employer?
      unless @applic.job.user == current_user
        redirect_to applics_path, alert: t("flash.not_authorized")
      end
    end
  end
end
