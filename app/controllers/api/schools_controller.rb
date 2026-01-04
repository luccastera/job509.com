module Api
  class SchoolsController < BaseController
    def index
      schools = Education.where.not(school: [nil, ""])
                         .distinct
                         .pluck(:school)
                         .sort

      # Filter by query
      if params[:q].present?
        schools = schools.select { |s| s.downcase.include?(params[:q].downcase) }
      end

      render json: schools.first(20).map { |name| { name: name } }
    end
  end
end
