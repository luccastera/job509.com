module Api
  class CompaniesController < BaseController
    def index
      companies = Job.approved
                     .where.not(company: [nil, ""])
                     .distinct
                     .pluck(:company)
                     .sort

      # Filter by query
      if params[:q].present?
        companies = companies.select { |c| c.downcase.include?(params[:q].downcase) }
      end

      render json: companies.first(20).map { |name| { name: name } }
    end
  end
end
