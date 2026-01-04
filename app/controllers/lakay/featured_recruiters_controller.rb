module Lakay
  class FeaturedRecruitersController < BaseController
    before_action :set_featured_recruiter, only: [:show, :edit, :update, :destroy]

    def index
      @featured_recruiters = FeaturedRecruiter.all
    end

    def show
    end

    def new
      @featured_recruiter = FeaturedRecruiter.new
    end

    def edit
    end

    def create
      @featured_recruiter = FeaturedRecruiter.new(featured_recruiter_params)

      if @featured_recruiter.save
        redirect_to lakay_featured_recruiters_path, notice: "Featured recruiter created."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def update
      if @featured_recruiter.update(featured_recruiter_params)
        redirect_to lakay_featured_recruiters_path, notice: "Featured recruiter updated."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @featured_recruiter.destroy
      redirect_to lakay_featured_recruiters_path, notice: "Featured recruiter deleted."
    end

    private

    def set_featured_recruiter
      @featured_recruiter = FeaturedRecruiter.find(params[:id])
    end

    def featured_recruiter_params
      params.require(:featured_recruiter).permit(:name, :website_url, :logo)
    end
  end
end
