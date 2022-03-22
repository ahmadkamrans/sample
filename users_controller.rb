class UsersController < ApplicationController
  authorize_resource :user
  expose_decorated :user

  # response formats
  responders :flash
  respond_to :html, :js

  # PATCH/PUT /users/1
  # PATCH/PUT /users/1.json
  def update
    self.user = User.find(params[:id])
    user.signature = Paperclip.base64_string_to_file('signature.png', 'image/png', user_params[:signature]) if user_params[:signature].present?

    # really prevent a user from setting super_admin even if they are purposeful about it
    raise CanCan::AccessDenied if user_params[:role] == 'super_admin' || user_params[:role] == '5'

    if needs_password? # with Devise if we pass in a password to change we need to pas in the conf & the current_password as well - this checks it
      user.update_with_password(user_params.except(:signature))
      bypass_sign_in(user) # we need to resign in the user after we change their password - Devise stuff
    else
      user.update(user_params.except(:signature, :password, :password_confirmation, :current_password))
    end

    notice = user_params[:email] == user.email ? 'User was successfully updated.' : 'User was successfully updated. Your email will change once you have confirmed it'
    respond_with user, location: current_user.id == user.id ? edit_user_path(user) : users_path, notice: notice
  end

  private

  # Never trust parameters from the scary internet, only allow the white list through.
  def user_params
    hash = params.require(:user).permit(
      :login, :name, :email, :role, :address_id, :password, :password_confirmation, :certification, :survey_certification, :default_gauge_id,
      :certification_expiration_date, :signature, :text_display_size, :current_password, :survey_certification_expiration_date, :self_help,
      address_attributes: ADDRESS_PARAMS,
      user_water_purveyor_certifications_attributes: %i[id water_purveyor_id certification
                                                        expiration_date comment _destroy water_purveyor_type],
      gauges_attributes: %i[id tester_id serial manufacturer model calibration_date company_id _destroy],
      fields: {}
    )
    hash.delete(:address_attributes) if hash[:address_attributes].try(:all?) { |_key, value| value.blank? }
    hash.delete(:role) unless can? :manage, User # make sure normal folks can't just enable the role box and change it.
    hash.delete(:password) unless user == current_user # No URL-scumming
    hash
  end

end
