class IpAddressesController < ApplicationController
  def new
    @ip = current_user.ip_addresses.new
  end

  def create
    @ip = current_user.ip_addresses.new(ip_address_params)

    if @ip.save_with_auto_assign
      IpAddressMailer.notify_to_user(current_user, request.ip, :create, @ip).deliver_now
      redirect_to root_path
    else
      render :new
    end
  end

  def show
    @ip = current_user.ip_addresses.find(params[:id])
  end

  def edit
    @ip = current_user.ip_addresses.find(params[:id])
    redirect_to root_path unless @ip.modifiable_by_user?
  end

  def update
    @ip = current_user.ip_addresses.find(params[:id])

    if @ip.update_attributes(update_ip_address_params)
      IpAddressMailer.notify_to_user(current_user, request.ip, :update, @ip).deliver_now
      redirect_to root_path, notice: 'IPの情報を更新しました。'
    else
      render :edit
    end
  end

  def destroy
    @ip = current_user.ip_addresses.find(params[:id])

    if @ip.destroy
      IpAddressMailer.notify_to_user(current_user, request.ip, :destroy, @ip).deliver_now
      redirect_to root_path, notice: 'IPを削除しました。'
    else
      render :edit
    end
  end

  private

  def ip_address_params
    params.require(:ip_address).permit(:domain, :affiliation, :mac_address)
  end

  def update_ip_address_params
    params.require(:ip_address).permit(:domain, :mac_address)
  end
end
