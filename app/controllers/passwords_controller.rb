class PasswordsController < Devise::PasswordsController
  before_action :set_devise_mapping

  protected

  def set_devise_mapping
    @devise_mapping ||= Devise.mappings[:user]
    request.env["devise.mapping"] = @devise_mapping
  end
end
