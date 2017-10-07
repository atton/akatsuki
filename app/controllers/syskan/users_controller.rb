class Syskan::UsersController < ApplicationController
  before_action :authenticate_syskan!

  def index
    @users = User.order(:uid).includes(ip_addresses: :virtual_machine)
  end

  def increment_vm_limit
    user = User.find params[:user_id]

    if user.update_attributes(vm_limit: user.vm_limit.succ)
      redirect_to syskan_users_path
    else
      redirect_to syskan_users_path, alert: user.errors.full_messages.join("\n")
    end
  end

  def decrement_vm_limit
    user = User.find params[:user_id]

    redirect_to syskan_users_path and return if user.vm_limit <= 0

    if user.update_attributes(vm_limit: user.vm_limit.pred)
      redirect_to syskan_users_path
    else
      redirect_to syskan_users_path, alert: user.errors.full_messages.join("\n")
    end
  end
end
