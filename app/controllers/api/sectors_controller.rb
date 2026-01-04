module Api
  class SectorsController < BaseController
    def index
      sectors = Sector.order(:name)

      # Filter by query
      if params[:q].present?
        sectors = sectors.where("name ILIKE ?", "%#{params[:q]}%")
      end

      render json: sectors.map { |s| { id: s.id, name: s.name } }
    end
  end
end
