module Lakay
  class JobSeekersController < BaseController
    before_action :set_job_seeker, only: [:show, :edit, :update, :destroy, :pdf, :recommend, :unrecommend, :comment, :login_as, :add_tag, :remove_tag, :add_to_list, :remove_from_list]

    # GET /lakay/job_seekers
    def index
      @job_seekers = User.job_seeker.includes(:resume).order(created_at: :desc)
      @pagy, @job_seekers = pagy(@job_seekers, limit: 25)
    end

    # GET /lakay/job_seekers/search
    def search
      @job_seekers = User.job_seeker.includes(:resume)

      if params[:q].present?
        @job_seekers = @job_seekers.where(
          "firstname ILIKE :q OR lastname ILIKE :q OR email ILIKE :q",
          q: "%#{params[:q]}%"
        )
      end

      @pagy, @job_seekers = pagy(@job_seekers.order(:lastname, :firstname), limit: 25)
      render :index
    end

    # GET /lakay/job_seekers/search_by_keyword
    def search_by_keyword
      @job_seekers = User.job_seeker
                         .joins(resume: :skills)
                         .where("skills.description ILIKE ?", "%#{params[:keyword]}%")
                         .distinct
                         .includes(:resume)

      @pagy, @job_seekers = pagy(@job_seekers.order(:lastname, :firstname), limit: 25)
      render :index
    end

    # POST /lakay/job_seekers/bulk_sms
    def bulk_sms
      @job_seeker_ids = params[:job_seeker_ids] || []
      @message = params[:message]

      if @job_seeker_ids.any? && @message.present?
        # TODO: Implement Twilio SMS sending
        flash[:notice] = "SMS sent to #{@job_seeker_ids.count} job seekers."
      else
        flash[:alert] = "Please select job seekers and enter a message."
      end

      redirect_to lakay_job_seekers_path
    end

    # GET /lakay/job_seekers/:id
    def show
      @resume = @job_seeker.resume
      @applications = @job_seeker.applics.includes(:job).recent
    end

    # GET /lakay/job_seekers/:id/pdf
    def pdf
      @resume = @job_seeker.resume
      respond_to do |format|
        format.pdf do
          pdf = ResumePdf.new(@resume)
          send_data pdf.render,
                    filename: "#{@job_seeker.full_name.parameterize}-resume.pdf",
                    type: "application/pdf"
        end
      end
    end

    # GET /lakay/job_seekers/new
    def new
      @job_seeker = User.new(role: :job_seeker)
    end

    # POST /lakay/job_seekers
    def create
      @job_seeker = User.new(job_seeker_params)
      @job_seeker.role = :job_seeker

      if @job_seeker.save
        redirect_to lakay_job_seeker_path(@job_seeker), notice: t("flash.created", resource: "Job Seeker")
      else
        render :new, status: :unprocessable_entity
      end
    end

    # GET /lakay/job_seekers/:id/edit
    def edit
    end

    # PATCH/PUT /lakay/job_seekers/:id
    def update
      if @job_seeker.update(job_seeker_params)
        redirect_to lakay_job_seeker_path(@job_seeker), notice: t("flash.updated", resource: "Job Seeker")
      else
        render :edit, status: :unprocessable_entity
      end
    end

    # DELETE /lakay/job_seekers/:id
    def destroy
      @job_seeker.destroy
      redirect_to lakay_job_seekers_path, notice: t("flash.deleted", resource: "Job Seeker")
    end

    # PATCH /lakay/job_seekers/:id/recommend
    def recommend
      @job_seeker.resume&.update(is_recommended: true)
      redirect_to lakay_job_seeker_path(@job_seeker), notice: "Job seeker has been recommended."
    end

    # PATCH /lakay/job_seekers/:id/unrecommend
    def unrecommend
      @job_seeker.resume&.update(is_recommended: false)
      redirect_to lakay_job_seeker_path(@job_seeker), notice: "Recommendation has been removed."
    end

    # POST /lakay/job_seekers/:id/comment
    def comment
      @job_seeker.update(job509_comments: params[:comment])
      redirect_to lakay_job_seeker_path(@job_seeker), notice: "Comment saved."
    end

    # POST /lakay/job_seekers/:id/login_as
    def login_as
      sign_in(@job_seeker)
      redirect_to root_path, notice: "You are now logged in as #{@job_seeker.full_name}"
    end

    # POST /lakay/job_seekers/:id/add_tag
    def add_tag
      tag = Tag.find(params[:tag_id])
      @job_seeker.tags << tag unless @job_seeker.tags.include?(tag)
      redirect_to lakay_job_seeker_path(@job_seeker), notice: "Tag '#{tag.name}' added."
    end

    # DELETE /lakay/job_seekers/:id/remove_tag
    def remove_tag
      tag = Tag.find(params[:tag_id])
      @job_seeker.tags.delete(tag)
      redirect_to lakay_job_seeker_path(@job_seeker), notice: "Tag '#{tag.name}' removed."
    end

    # POST /lakay/job_seekers/:id/add_to_list
    def add_to_list
      list = List.find(params[:list_id])
      list.users << @job_seeker unless list.users.include?(@job_seeker)
      redirect_to lakay_job_seeker_path(@job_seeker), notice: "Added to list '#{list.name}'."
    end

    # DELETE /lakay/job_seekers/:id/remove_from_list
    def remove_from_list
      list = List.find(params[:list_id])
      list.users.delete(@job_seeker)
      redirect_to lakay_job_seeker_path(@job_seeker), notice: "Removed from list '#{list.name}'."
    end

    private

    def set_job_seeker
      @job_seeker = User.job_seeker.find(params[:id])
    end

    def job_seeker_params
      params.require(:user).permit(
        :email, :password, :password_confirmation,
        :firstname, :lastname, :phone, :alternate_phone, :job509_comments
      )
    end
  end
end
