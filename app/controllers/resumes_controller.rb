class ResumesController < ApplicationController
  before_action :authenticate_user!
  before_action :require_job_seeker!, except: [:show, :pdf]
  before_action :set_resume, only: [:show, :edit, :update, :preview, :pdf]
  before_action :authorize_resume_access!, only: [:show, :pdf]

  # GET /resume
  def show
  end

  # GET /resume/edit
  def edit
    @resume = current_user.resume || current_user.create_resume!(sex: "M", objective: "")
    load_form_options
  end

  # PATCH /resume
  def update
    @resume = current_user.resume || current_user.create_resume!(sex: "M", objective: "")

    if @resume.update(resume_params)
      respond_to do |format|
        format.html { redirect_to resume_path, notice: t("flash.updated", resource: t("activerecord.models.resume")) }
        format.turbo_stream { flash.now[:notice] = t("flash.updated", resource: t("activerecord.models.resume")) }
      end
    else
      load_form_options
      render :edit, status: :unprocessable_entity
    end
  end

  # GET /resume/preview
  def preview
    render layout: "print"
  end

  # GET /resume/pdf
  def pdf
    respond_to do |format|
      format.pdf do
        pdf = ResumePdf.new(@resume)
        send_data pdf.render,
                  filename: "#{@resume.user.full_name.parameterize}-resume.pdf",
                  type: "application/pdf",
                  disposition: "inline"
      end
    end
  end

  private

  def set_resume
    if params[:id]
      @resume = Resume.find(params[:id])
    else
      @resume = current_user&.resume
    end
  end

  def authorize_resume_access!
    return if @resume.nil?
    return if current_user == @resume.user
    return if current_user&.employer?
    return if admin_signed_in?

    redirect_to root_path, alert: t("flash.not_authorized")
  end

  def resume_params
    params.require(:resume).permit(
      :objective, :sex, :birth_year, :nationality_id, :sector_id,
      :country_id, :city_id, :address1, :address2, :postal_code,
      :has_drivers_license, :years_of_experience
    )
  end

  def load_form_options
    @sectors = Sector.alphabetical
    @countries = Country.alphabetical
    @cities = City.alphabetical
    @languages = Language.alphabetical
  end
end
