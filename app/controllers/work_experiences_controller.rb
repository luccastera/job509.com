class WorkExperiencesController < ApplicationController
  before_action :authenticate_user!
  before_action :require_job_seeker!
  before_action :set_resume
  before_action :set_work_experience, only: [:update, :destroy]

  # POST /resume/work_experiences
  def create
    @work_experience = @resume.work_experiences.build(work_experience_params)

    if @work_experience.save
      redirect_to edit_resume_path, notice: t("flash.created", resource: t("activerecord.models.work_experience"))
    else
      redirect_to edit_resume_path, alert: @work_experience.errors.full_messages.join(", ")
    end
  end

  # PATCH /resume/work_experiences/:id
  def update
    if @work_experience.update(work_experience_params)
      redirect_to edit_resume_path, notice: t("flash.updated", resource: t("activerecord.models.work_experience"))
    else
      redirect_to edit_resume_path, alert: @work_experience.errors.full_messages.join(", ")
    end
  end

  # DELETE /resume/work_experiences/:id
  def destroy
    @work_experience.destroy
    redirect_to edit_resume_path, notice: t("flash.deleted", resource: t("activerecord.models.work_experience"))
  end

  private

  def set_resume
    @resume = current_user.resume
    redirect_to edit_resume_path, alert: "Please create your resume first." unless @resume
  end

  def set_work_experience
    @work_experience = @resume.work_experiences.find(params[:id])
  end

  def work_experience_params
    params.require(:work_experience).permit(
      :company, :title, :description, :country_id, :city_id,
      :starting_month, :starting_year, :ending_month, :ending_year,
      :is_current, :jobtype_id, :sector_id, :monthly_salary
    )
  end
end
