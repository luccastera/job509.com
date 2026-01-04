class LanguageSkillsController < ApplicationController
  before_action :authenticate_user!
  before_action :require_job_seeker!
  before_action :set_resume
  before_action :set_language_skill, only: [:update, :destroy]

  def create
    @language_skill = @resume.language_skills.build(language_skill_params)

    if @language_skill.save
      redirect_to edit_resume_path, notice: t("flash.created", resource: t("activerecord.models.language_skill"))
    else
      redirect_to edit_resume_path, alert: @language_skill.errors.full_messages.join(", ")
    end
  end

  def update
    if @language_skill.update(language_skill_params)
      redirect_to edit_resume_path, notice: t("flash.updated", resource: t("activerecord.models.language_skill"))
    else
      redirect_to edit_resume_path, alert: @language_skill.errors.full_messages.join(", ")
    end
  end

  def destroy
    @language_skill.destroy
    redirect_to edit_resume_path, notice: t("flash.deleted", resource: t("activerecord.models.language_skill"))
  end

  private

  def set_resume
    @resume = current_user.resume
    redirect_to edit_resume_path, alert: "Please create your resume first." unless @resume
  end

  def set_language_skill
    @language_skill = @resume.language_skills.find(params[:id])
  end

  def language_skill_params
    params.require(:language_skill).permit(:language_id, :speaking_level, :writing_level)
  end
end
