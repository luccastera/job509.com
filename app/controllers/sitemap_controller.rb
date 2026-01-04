class SitemapController < ApplicationController
  def index
    @jobs = Job.approved.active.order(post_date: :desc)
    @events = Event.upcoming

    respond_to do |format|
      format.xml
    end
  end
end
