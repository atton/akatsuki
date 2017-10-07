class Ldap::UsersController < ApplicationController
  before_action :authenticate_iesudoer!, except: [:edit, :update]

  def new
    @user = LDAP::User.new
  end

  def create
    @user = LDAP::User.new
    @user.set_attributes_from_form_parameters(new_ldap_user_params)

    @user.save!

    logger.info "Create new LDAP user #{@user}"
    flash[:notice] = "LDAP User create succesfully. #{@user.uid}"
    redirect_to root_path
  rescue => e
    @user.errors.add(:ldap, e.message)
    render :new
  end

  def edit
    @user = current_user.ldap_user
  end

  def update
    @user = current_user.ldap_user
    @user.set_update_attributes_from_params(update_ldap_user_params)

    if @user.password_modifiable_by_akatsuki? and ldap_user_password_params[:userPassword].present?
      @user.set_passwords_from_form_parameters(ldap_user_password_params)
    else
      @user.userPassword_confirmation = @user.userPassword
    end

    notice = @user.notice_from_changes

    if @user.save
      redirect_to root_path, notice: notice
    else
      render :edit
    end
  end

  private

  def new_ldap_user_params
    params.require(:user).permit(:uid, :uidNumber, :gecos, :group, :cn, :password)
  end

  def update_ldap_user_params
    params.require(:attributes).permit(:loginShell, IEConfig::LDAP::MaxNumberOfEdyID.times.map{|n| "ldapedyid_#{n}"})
  end

  def ldap_user_password_params
    params.require(:attributes).permit(:userPassword, :userPassword_confirmation, :current_password)
  end
end
