class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  # Pagy for pagination
  include Pagy::Backend

  # Before actions
  before_action :set_locale
  before_action :configure_permitted_parameters, if: :devise_controller?

  # Helper methods available in views
  helper_method :current_admin, :admin_signed_in?

  protected

  # Devise: permit custom parameters
  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:firstname, :lastname, :phone, :alternate_phone, :role])
    devise_parameter_sanitizer.permit(:account_update, keys: [:firstname, :lastname, :phone, :alternate_phone])
  end

  # Set locale from params, session, or default
  def set_locale
    if params[:locale].present?
      locale = params[:locale].to_sym
      if I18n.available_locales.include?(locale)
        session[:locale] = locale
        I18n.locale = locale
      else
        I18n.locale = session[:locale] || I18n.default_locale
      end
    else
      I18n.locale = session[:locale] || I18n.default_locale
    end
  end

  def default_url_options
    { locale: I18n.locale == I18n.default_locale ? nil : I18n.locale }
  end

  # Admin authentication (separate from Devise users)
  def current_admin
    @current_admin ||= Administrator.find_by(id: session[:admin_id]) if session[:admin_id]
  end

  def admin_signed_in?
    current_admin.present?
  end

  def authenticate_admin!
    unless admin_signed_in?
      flash[:alert] = t("flash.login_required")
      redirect_to lakay_login_path
    end
  end

  def authorize_super_admin!
    unless current_admin&.super_admin?
      flash[:alert] = t("flash.not_authorized")
      redirect_to lakay_root_path
    end
  end

  # Authorization helpers for users
  def require_employer!
    unless current_user&.employer?
      flash[:alert] = t("flash.not_authorized")
      redirect_to root_path
    end
  end

  def require_job_seeker!
    unless current_user&.job_seeker?
      flash[:alert] = t("flash.not_authorized")
      redirect_to root_path
    end
  end

  # After sign in path for Devise
  def after_sign_in_path_for(resource)
    stored_location_for(resource) || (resource.employer? ? employer_jobs_path : root_path)
  end

  # After sign out path for Devise
  def after_sign_out_path_for(_resource_or_scope)
    root_path
  end
end
