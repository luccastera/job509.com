class JobsController < ApplicationController
  include Pagy::Backend

  before_action :authenticate_user!, except: [:index, :show, :search, :live_search, :filter]
  before_action :require_employer!, only: [:new, :create, :edit, :update, :destroy, :employer, :applications]
  before_action :require_job_seeker!, only: [:myjobs, :apply, :submit_application]
  before_action :set_job, only: [:show, :edit, :update, :destroy, :apply, :submit_application]
  before_action :authorize_job_owner!, only: [:edit, :update, :destroy]

  # GET /jobs
  def index
    @jobs = Job.active.includes(:sector, :country, :city, :jobtype).recent
    @jobs = @jobs.by_sector(params[:sector_id]) if params[:sector_id].present?
    @jobs = @jobs.by_city(params[:city_id]) if params[:city_id].present?

    @pagy, @jobs = pagy(@jobs, limit: 20)
    @sectors = Sector.alphabetical
    @cities = City.alphabetical
  end

  # GET /jobs/:id
  def show
    @related_jobs = Job.active
                       .where(sector_id: @job.sector_id)
                       .where.not(id: @job.id)
                       .limit(5)
  end

  # GET /jobs/new
  def new
    @job = current_user.jobs.build
    @job.post_date = Date.current
    load_form_options
  end

  # POST /jobs
  def create
    @job = current_user.jobs.build(job_params)
    @job.approved = false

    if @job.save
      redirect_to @job, notice: t("flash.created", resource: t("activerecord.models.job"))
    else
      load_form_options
      render :new, status: :unprocessable_entity
    end
  end

  # GET /jobs/:id/edit
  def edit
    load_form_options
  end

  # PATCH/PUT /jobs/:id
  def update
    if @job.update(job_params)
      redirect_to @job, notice: t("flash.updated", resource: t("activerecord.models.job"))
    else
      load_form_options
      render :edit, status: :unprocessable_entity
    end
  end

  # DELETE /jobs/:id
  def destroy
    @job.destroy
    redirect_to employer_jobs_path, notice: t("flash.deleted", resource: t("activerecord.models.job"))
  end

  # GET /jobs/search
  def search
    @query = params[:q]
    @jobs = Job.active.includes(:sector, :country, :city, :jobtype)

    if @query.present?
      @jobs = @jobs.where(
        "title ILIKE :q OR company ILIKE :q OR description ILIKE :q",
        q: "%#{@query}%"
      )
    end

    @jobs = @jobs.by_sector(params[:sector_id]) if params[:sector_id].present?
    @jobs = @jobs.by_city(params[:city_id]) if params[:city_id].present?
    @jobs = @jobs.recent

    @pagy, @jobs = pagy(@jobs, limit: 20)
    @sectors = Sector.alphabetical
    @cities = City.alphabetical

    render :index
  end

  # GET /jobs/live_search (AJAX)
  def live_search
    @jobs = Job.active
               .where("title ILIKE :q OR company ILIKE :q", q: "%#{params[:q]}%")
               .limit(10)

    render partial: "jobs/search_results", locals: { jobs: @jobs }
  end

  # GET /jobs/filter
  def filter
    @jobs = Job.active.includes(:sector, :country, :city, :jobtype).recent
    @jobs = @jobs.by_sector(params[:sector_id]) if params[:sector_id].present?
    @jobs = @jobs.by_city(params[:city_id]) if params[:city_id].present?

    @pagy, @jobs = pagy(@jobs, limit: 20)

    respond_to do |format|
      format.html { render :index }
      format.turbo_stream
    end
  end

  # GET /jobs/myjobs (Job seeker's applications)
  def myjobs
    @applics = current_user.applics.includes(job: [:sector, :country, :city]).recent
    @pagy, @applics = pagy(@applics, limit: 20)
  end

  # GET /jobs/employer (Employer's posted jobs)
  def employer
    @jobs = current_user.jobs.includes(:sector, :country, :city).recent
    @pagy, @jobs = pagy(@jobs, limit: 20)
  end

  # GET /jobs/applications (Employer views all applicants)
  def applications
    @jobs = current_user.jobs.includes(:applics).where("applics.id IS NOT NULL").references(:applics)
  end

  # GET /jobs/:id/apply
  def apply
    if current_user.applics.exists?(job_id: @job.id)
      redirect_to @job, alert: t("applications.already_applied", default: "You have already applied to this job.")
      return
    end

    @applic = current_user.applics.build(job: @job)
  end

  # POST /jobs/:id/submit_application
  def submit_application
    @applic = current_user.applics.build(applic_params)
    @applic.job = @job

    if @applic.save
      redirect_to myjobs_jobs_path, notice: t("applications.submitted", default: "Your application has been submitted successfully!")
    else
      render :apply, status: :unprocessable_entity
    end
  end

  private

  def set_job
    @job = Job.find(params[:id])
  end

  def authorize_job_owner!
    unless @job.user == current_user
      redirect_to jobs_path, alert: t("flash.not_authorized")
    end
  end

  def job_params
    params.require(:job).permit(
      :title, :company, :company_url, :company_description,
      :description, :qualifications, :jobtype_id, :sector_id,
      :country_id, :city_id, :post_date, :apply_url
    )
  end

  def applic_params
    params.require(:applic).permit(:cover_letter)
  end

  def load_form_options
    @sectors = Sector.alphabetical
    @jobtypes = Jobtype.alphabetical
    @countries = Country.alphabetical
    @cities = City.alphabetical
  end
end
