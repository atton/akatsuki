class Syskan::VirtualMachinesController < ApplicationController
  before_action :authenticate_syskan!

  def index
    @virtual_machines = VirtualMachine.order(:created_at)
  end

  def toggle_cleanup_marked
    vm = VirtualMachine.find params[:virtual_machine_id]
    vm.cleanup_marked = !vm.cleanup_marked

    if vm.save
      redirect_to syskan_virtual_machines_path
    else
      redirect_to syskan_virtual_machines_path, alert: user.errors.full_messages.join("\n")
    end
  end
end

