class SkillsController < ApplicationController
  before_action :authenticate_user!
  before_action :require_job_seeker!
  before_action :set_resume
  before_action :set_skill, only: [:update, :destroy]

  def create
    @skill = @resume.skills.build(skill_params)

    if @skill.save
      redirect_to edit_resume_path, notice: t("flash.created", resource: t("activerecord.models.skill"))
    else
      redirect_to edit_resume_path, alert: @skill.errors.full_messages.join(", ")
    end
  end

  def update
    if @skill.update(skill_params)
      redirect_to edit_resume_path, notice: t("flash.updated", resource: t("activerecord.models.skill"))
    else
      redirect_to edit_resume_path, alert: @skill.errors.full_messages.join(", ")
    end
  end

  def destroy
    @skill.destroy
    redirect_to edit_resume_path, notice: t("flash.deleted", resource: t("activerecord.models.skill"))
  end

  private

  def set_resume
    @resume = current_user.resume
    redirect_to edit_resume_path, alert: "Please create your resume first." unless @resume
  end

  def set_skill
    @skill = @resume.skills.find(params[:id])
  end

  def skill_params
    params.require(:skill).permit(:description)
  end
end
