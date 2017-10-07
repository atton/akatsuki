module PermissionHelper

  def current_user
    return nil if session[:uid].blank?
    User.find_or_create_by(uid: session[:uid])
  end

  def user_signed_in?
    current_user.present?
  end

  def syskan_signed_in?
    session[:ldap_groups].present? && session[:ldap_groups].include?('syskan')
  end

  def iesudoer_signed_in?
    session[:ldap_groups].present? && session[:ldap_groups].include?('iesudoers')
  end

end

