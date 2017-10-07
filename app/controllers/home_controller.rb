class HomeController < ApplicationController
  skip_before_filter :authenticate_user!,  only: [:sign_in, :new_session]

  def index
    all_ips           = current_user.ip_addresses.includes(:virtual_machine)
    @ip_addresses     = all_ips.select{|s| s.virtual_machine.blank?}
    @virtual_machines = all_ips - @ip_addresses
  end

  def new_session
    user = LDAP::User.find(sign_in_params[:uid])

    unless user.bind(sign_in_params[:password])
      sign_out_user
      raise 'ログインに失敗しました。uidかパスワードが間違っています。'
    end

    if user.graduate?
      sign_out_user
      raise '卒業生はログインできません。'
    end

    sign_in_user(sign_in_params[:uid])
    redirect_to root_path, notice: 'ログインに成功しました。'
  rescue ActiveLdap::AuthenticationError => e
    redirect_to sign_in_path, alert: 'ログインに失敗しました。uidかパスワードが間違っています。'
  rescue => e
    redirect_to sign_in_path, alert: e.message
  end

  def sign_in
  end

  def sign_out
    sign_out_user
    redirect_to sign_in_path, notice: 'ログアウトしました。'
  end

  private

  def sign_in_params
    params.permit(:uid, :password)
  end
end
