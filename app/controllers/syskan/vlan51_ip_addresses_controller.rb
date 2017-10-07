class Syskan::Vlan51IpAddressesController < ApplicationController
  before_action :authenticate_syskan!

  def index
    @ip_addresses = IpAddress.where(vlan: 51).order(assigned_address: :asc)
  end

  def new
    @ip = IpAddress.new
  end

  def create
    @ip = IpAddress.new(new_params.merge(affiliation: 'os', vlan: 51))

    unless User.exists?(uid: @ip.domain)
      @ip.errors.add(:uid, "uid not found : #{@ip.domain}")
      render :new and return
    end

    if @ip.save_with_auto_assign
      redirect_to :index, notice: 'Add new IP Address to VLAN51 successfully'
    else
      render :new
    end
  end

  def destroy
    @ip = IpAddress.find_by(id: params[:id], vlan: 51)

    if @ip.destroy
      redirect_to :index, notice: 'Remove IP Address to VLAN51 successfully'
    else
      render :new
    end
  end

  private

  def new_params
    params.require(:syskan_vlan51_ip_address).permit(:domain, :mac_address)
  end
end
