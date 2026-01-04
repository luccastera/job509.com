class ShareController < ApplicationController
  def show
    @share_token = ShareToken.find_by!(token: params[:token])

    if @share_token.expired?
      render :expired
    else
      @resume = @share_token.resume
      render "resumes/show"
    end
  rescue ActiveRecord::RecordNotFound
    render :not_found, status: :not_found
  end
end
