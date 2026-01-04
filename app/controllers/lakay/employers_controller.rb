module Lakay
  class EmployersController < BaseController
    before_action :set_employer, only: [:show, :edit, :update, :destroy, :convert]

    def index
      @employers = User.employer.order(created_at: :desc)
      @pagy, @employers = pagy(@employers, limit: 25)
    end

    def show
      @jobs = @employer.jobs.order(created_at: :desc)
    end

    def new
      @employer = User.new(role: :employer)
    end

    def create
      @employer = User.new(employer_params)
      @employer.role = :employer

      if @employer.save
        redirect_to lakay_employer_path(@employer), notice: t("flash.created", resource: "Employer")
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      if @employer.update(employer_params)
        redirect_to lakay_employer_path(@employer), notice: t("flash.updated", resource: "Employer")
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @employer.destroy
      redirect_to lakay_employers_path, notice: t("flash.deleted", resource: "Employer")
    end

    def convert
      @employer.update(role: :job_seeker)
      redirect_to lakay_job_seekers_path, notice: "Employer converted to job seeker."
    end

    private

    def set_employer
      @employer = User.employer.find(params[:id])
    end

    def employer_params
      params.require(:user).permit(
        :email, :password, :password_confirmation,
        :firstname, :lastname, :phone, :alternate_phone, :job509_comments
      )
    end
  end
end
