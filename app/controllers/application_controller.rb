class ApplicationController < ActionController::Base
  include PermissionHelper

  before_action :authenticate_user!
  before_action :refresh_ldap_connection

  rescue_from ActiveRecord::RecordNotFound do
    redirect_to root_path
  end
  rescue_from Exception, with: :unhandled_error

  def sign_in_user uid
    session[:uid]         = uid
    session[:ldap_groups] = current_user.ldap_user.groups.map(&:cn)
  end

  def sign_out_user
    session.delete(:uid)
    session.delete(:ldap_groups)
  end

  def authenticate_user!
    return if session[:uid].present?

    sign_out_user
    redirect_to sign_in_path, notice: 'ログインしてください。' if session[:uid].blank?
  end

  def authenticate_syskan!
    unless syskan_signed_in?
      redirect_to root_path
    end
  end

  def authenticate_iesudoer!
    unless iesudoer_signed_in?
      redirect_to root_path
    end
  end

  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  private

  def unhandled_error exception=nil
    logger.fatal exception.message if exception.present?
    redirect_to root_path, alert: exception.try(:message)
  end

  def refresh_ldap_connection
    ActiveLdap::Base.clear_active_connections!
  end
end
