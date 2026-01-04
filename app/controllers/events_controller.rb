class EventsController < ApplicationController
  before_action :set_event, only: [:show, :signup, :register]

  # GET /events
  def index
    @upcoming_events = Event.upcoming.limit(10)
    @past_events = Event.past.limit(10)
  end

  # GET /events/:id
  def show
  end

  # GET /events/:id/signup
  def signup
    @attendee = @event.attendees.build
  end

  # POST /events/:id/register
  def register
    @attendee = @event.attendees.build(attendee_params)

    if @attendee.save
      redirect_to @event, notice: t("events.registered", default: "You have been registered for this event!")
    else
      render :signup, status: :unprocessable_entity
    end
  end

  private

  def set_event
    @event = Event.find(params[:id])
  end

  def attendee_params
    params.require(:attendee).permit(:firstname, :lastname, :company, :phone, :email)
  end
end
