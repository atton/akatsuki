class VirtualMachinesController < ApplicationController
  before_action :check_vm_permission,  only:   [:new, :create]
  before_action :find_virtual_machine, except: [:new, :create]

  def new
  end

  def create
    @virtual_machine = VirtualMachine.new

    if @virtual_machine.save_from_submit_form(virtual_machine_params)
      current_user.update_attributes(vm_limit: current_user.vm_limit.pred)
      IpAddressMailer.notify_to_user(current_user, request.ip, :create, @virtual_machine.ip_address).deliver_now
      redirect_to root_path, notice: 'VMを作成しました'
    else
      render :new
    end
  end

  def show
    @vm_information  = @virtual_machine.information
  end

  def power_on
    @virtual_machine.power_on unless @virtual_machine.active?
    redirect_to ip_address_virtual_machine_path(@virtual_machine.ip_address)
  end

  def power_off
    @virtual_machine.power_off if @virtual_machine.active?
    redirect_to ip_address_virtual_machine_path(@virtual_machine.ip_address)
  end

  private

  def check_vm_permission
    redirect_to root_path unless current_user.vm_creatable?
  end

  def find_virtual_machine
    @virtual_machine = current_user.ip_addresses.find(params[:ip_address_id]).virtual_machine
  end

  def virtual_machine_params
    params.require(:virtual_machine).permit(:domain, :affiliation, :template_name).merge(user_id:current_user.id)
  end
end
