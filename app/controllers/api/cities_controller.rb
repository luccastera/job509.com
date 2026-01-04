module Api
  class CitiesController < BaseController
    def index
      cities = City.includes(:country).order(:name)

      # Filter by country
      if params[:country_id].present?
        cities = cities.where(country_id: params[:country_id])
      end

      # Filter by query
      if params[:q].present?
        cities = cities.where("cities.name ILIKE ?", "%#{params[:q]}%")
      end

      render json: cities.map { |c|
        {
          id: c.id,
          name: c.name,
          country: c.country&.name,
          latitude: c.latitude,
          longitude: c.longitude
        }
      }
    end
  end
end
