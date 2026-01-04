module Lakay
  class EventsController < BaseController
    before_action :set_event, only: [:show, :edit, :update, :destroy, :attendees]

    def index
      @events = Event.order(starts_at: :desc)
      @pagy, @events = pagy(@events, limit: 25)
    end

    def show
    end

    def attendees
      @attendees = @event.attendees.order(:lastname, :firstname)
    end

    def new
      @event = Event.new
    end

    def create
      @event = Event.new(event_params)

      if @event.save
        redirect_to [:lakay, @event], notice: t("flash.created", resource: "Event")
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      if @event.update(event_params)
        redirect_to [:lakay, @event], notice: t("flash.updated", resource: "Event")
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @event.destroy
      redirect_to lakay_events_path, notice: t("flash.deleted", resource: "Event")
    end

    private

    def set_event
      @event = Event.find(params[:id])
    end

    def event_params
      params.require(:event).permit(
        :name, :description, :starts_at, :ends_at, :location,
        :youtube_url, :cost, :small_image, :big_image
      )
    end
  end
end
