module Lakay
  class DashboardController < BaseController
    # GET /lakay
    def index
      @total_users = User.count
      @total_job_seekers = User.job_seeker.count
      @total_employers = User.employer.count
      @total_jobs = Job.count
      @pending_jobs = Job.pending.count
      @active_jobs = Job.active.count
      @total_applications = Applic.count
      @recent_users = User.order(created_at: :desc).limit(10)
      @recent_jobs = Job.order(created_at: :desc).limit(10)
    end

    # GET /lakay/stats
    def stats
      @jobs_by_sector = Job.group(:sector_id).count
      @users_by_role = User.group(:role).count
    end

    # GET /lakay/accounting
    def accounting
      @paid_jobs = Job.where.not(payment_amount: nil).order(payment_date: :desc)
      @total_revenue = @paid_jobs.sum(:payment_amount)
    end

    # GET /lakay/language_stats
    def language_stats
      @language_skills_count = LanguageSkill.group(:language_id).count
    end

    # GET /lakay/email_lists
    def email_lists
      @job_seeker_emails = User.job_seeker.pluck(:email)
      @employer_emails = User.employer.pluck(:email)
    end
  end
end
