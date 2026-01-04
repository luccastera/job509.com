class FeedController < ApplicationController
  def index
    @jobs = Job.approved.active.order(post_date: :desc).limit(50)

    respond_to do |format|
      format.rss { render layout: false }
    end
  end
end
