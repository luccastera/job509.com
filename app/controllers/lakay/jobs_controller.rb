module Lakay
  class JobsController < BaseController
    before_action :set_job, only: [:show, :edit, :update, :destroy, :approve, :reject]

    # GET /lakay/jobs
    def index
      @jobs = Job.includes(:user, :sector, :country).order(created_at: :desc)
      @pagy, @jobs = pagy(@jobs, limit: 25)
    end

    # GET /lakay/jobs/approvals
    def approvals
      @jobs = Job.pending.includes(:user, :sector, :country).order(created_at: :desc)
      @pagy, @jobs = pagy(@jobs, limit: 25)
    end

    # GET /lakay/jobs/:id
    def show
      @applications = @job.applics.includes(:user).recent
    end

    # GET /lakay/jobs/new
    def new
      @job = Job.new
      load_form_options
    end

    # POST /lakay/jobs
    def create
      @job = Job.new(job_params)

      if @job.save
        redirect_to [:lakay, @job], notice: t("flash.created", resource: "Job")
      else
        load_form_options
        render :new, status: :unprocessable_entity
      end
    end

    # GET /lakay/jobs/:id/edit
    def edit
      load_form_options
    end

    # PATCH/PUT /lakay/jobs/:id
    def update
      if @job.update(job_params)
        redirect_to [:lakay, @job], notice: t("flash.updated", resource: "Job")
      else
        load_form_options
        render :edit, status: :unprocessable_entity
      end
    end

    # DELETE /lakay/jobs/:id
    def destroy
      @job.destroy
      redirect_to lakay_jobs_path, notice: t("flash.deleted", resource: "Job")
    end

    # PATCH /lakay/jobs/:id/approve
    def approve
      @job.update(approved: true)
      redirect_to approvals_lakay_jobs_path, notice: "Job has been approved."
    end

    # PATCH /lakay/jobs/:id/reject
    def reject
      @job.update(approved: false, expired: true)
      redirect_to approvals_lakay_jobs_path, notice: "Job has been rejected."
    end

    private

    def set_job
      @job = Job.find(params[:id])
    end

    def job_params
      params.require(:job).permit(
        :title, :company, :company_url, :company_description,
        :description, :qualifications, :user_id, :jobtype_id, :sector_id,
        :country_id, :city_id, :approved, :expired, :post_date, :apply_url,
        :payment_amount, :payment_type, :payment_date, :payment_comment
      )
    end

    def load_form_options
      @sectors = Sector.alphabetical
      @jobtypes = Jobtype.alphabetical
      @countries = Country.alphabetical
      @cities = City.alphabetical
      @employers = User.employer.order(:lastname, :firstname)
    end
  end
end
