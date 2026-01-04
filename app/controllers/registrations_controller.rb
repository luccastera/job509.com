class RegistrationsController < Devise::RegistrationsController
  before_action :set_devise_mapping
  before_action :configure_sign_up_params, only: [:create, :create_employer]

  # GET /signup
  def new
    build_resource
    resource.role = :job_seeker
    yield resource if block_given?
    respond_with resource
  end

  # GET /emp_signup
  def new_employer
    build_resource
    resource.role = :employer
    render :new_employer
  end

  # POST /signup
  def create
    build_resource(sign_up_params)
    resource.role = :job_seeker

    resource.save
    yield resource if block_given?

    if resource.persisted?
      if resource.active_for_authentication?
        set_flash_message!(:notice, :signed_up)
        sign_up(resource_name, resource)
        respond_with resource, location: after_sign_up_path_for(resource)
      else
        set_flash_message!(:notice, :"signed_up_but_#{resource.inactive_message}")
        expire_data_after_sign_in!
        respond_with resource, location: after_inactive_sign_up_path_for(resource)
      end
    else
      clean_up_passwords resource
      set_minimum_password_length
      respond_with resource
    end
  end

  # POST /emp_signup
  def create_employer
    build_resource(sign_up_params)
    resource.role = :employer

    resource.save
    yield resource if block_given?

    if resource.persisted?
      if resource.active_for_authentication?
        set_flash_message!(:notice, :signed_up)
        sign_up(resource_name, resource)
        respond_with resource, location: after_sign_up_path_for(resource)
      else
        set_flash_message!(:notice, :"signed_up_but_#{resource.inactive_message}")
        expire_data_after_sign_in!
        respond_with resource, location: after_inactive_sign_up_path_for(resource)
      end
    else
      clean_up_passwords resource
      set_minimum_password_length
      render :new_employer
    end
  end

  protected

  def set_devise_mapping
    @devise_mapping ||= Devise.mappings[:user]
    request.env["devise.mapping"] = @devise_mapping
  end

  def configure_sign_up_params
    devise_parameter_sanitizer.permit(:sign_up, keys: [:firstname, :lastname, :phone, :alternate_phone, :role])
  end

  def after_sign_up_path_for(resource)
    if resource.employer?
      new_job_path
    else
      edit_resume_path
    end
  end
end
