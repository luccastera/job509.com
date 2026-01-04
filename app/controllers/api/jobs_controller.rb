module Api
  class JobsController < BaseController
    def index
      @jobs = Job.approved.active.includes(:sector, :jobtype, :city)

      # Filter by sector
      if params[:sector_id].present?
        @jobs = @jobs.where(sector_id: params[:sector_id])
      end

      # Filter by city
      if params[:city_id].present?
        @jobs = @jobs.where(city_id: params[:city_id])
      end

      # Search by keyword
      if params[:q].present?
        @jobs = @jobs.where(
          "title ILIKE :q OR company ILIKE :q OR description ILIKE :q",
          q: "%#{params[:q]}%"
        )
      end

      @jobs = @jobs.order(post_date: :desc).limit(params[:limit] || 50)

      render json: @jobs.map { |job| job_json(job) }
    end

    def show
      @job = Job.approved.find(params[:id])
      render json: job_json(@job, full: true)
    rescue ActiveRecord::RecordNotFound
      render json: { error: "Job not found" }, status: :not_found
    end

    private

    def job_json(job, full: false)
      data = {
        id: job.id,
        title: job.title,
        company: job.company,
        location: job.city&.name,
        sector: job.sector&.name,
        job_type: job.jobtype&.name,
        post_date: job.post_date&.iso8601,
        url: job_url(job)
      }

      if full
        data.merge!(
          company_url: job.company_url,
          company_description: job.company_description,
          description: job.description,
          qualifications: job.qualifications,
          apply_url: job.apply_url
        )
      end

      data
    end
  end
end
