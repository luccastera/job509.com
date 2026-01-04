class EducationsController < ApplicationController
  before_action :authenticate_user!
  before_action :require_job_seeker!
  before_action :set_resume
  before_action :set_education, only: [:update, :destroy]

  # POST /resume/educations
  def create
    @education = @resume.educations.build(education_params)

    if @education.save
      redirect_to edit_resume_path, notice: t("flash.created", resource: t("activerecord.models.education"))
    else
      redirect_to edit_resume_path, alert: @education.errors.full_messages.join(", ")
    end
  end

  # PATCH /resume/educations/:id
  def update
    if @education.update(education_params)
      redirect_to edit_resume_path, notice: t("flash.updated", resource: t("activerecord.models.education"))
    else
      redirect_to edit_resume_path, alert: @education.errors.full_messages.join(", ")
    end
  end

  # DELETE /resume/educations/:id
  def destroy
    @education.destroy
    redirect_to edit_resume_path, notice: t("flash.deleted", resource: t("activerecord.models.education"))
  end

  private

  def set_resume
    @resume = current_user.resume
    redirect_to edit_resume_path, alert: "Please create your resume first." unless @resume
  end

  def set_education
    @education = @resume.educations.find(params[:id])
  end

  def education_params
    params.require(:education).permit(
      :diploma, :school, :graduation_year, :field_of_study,
      :country_id, :city_id, :is_completed, :comments
    )
  end
end
