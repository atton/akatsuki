namespace :virtual_machine do

  def puts_vm_info virtual_machines
    info = virtual_machines.map{|vm| [vm.ip_address.user.uid, vm.name, vm.ip_address.assigned_address,
                                      vm.ip_address.mac_address, vm.kvm_hostname].join(', ')}
    puts 'owner uid, vm name, vm IP, vm mac address, kvm location'
    puts info.join("\n")
  end

  desc 'Show list of archive candidates VM'
  task show_archive_candidate_virtual_machines: :environment do
    puts_vm_info VirtualMachine.where(cleanup_marked: true).order(:name).includes(ip_address: :user)
  end

  desc 'Show list of not archive candidates VM'
  task show_not_archive_candidate_virtual_machines: :environment do
    puts_vm_info VirtualMachine.where(cleanup_marked: false).order(:name).includes(ip_address: :user)
  end

  desc 'Move volumes in virtual machines from rental pool to archive pool'
  task archive_virtual_machines: :environment do
    vms  = VirtualMachine.where(cleanup_marked: true).order(:name).includes(ip_address: :user)
    vms.each do |vm|
      vm.power_off if vm.active?
      puts [vm.ip_address.user.uid, vm.name, vm.ip_address.assigned_address,
            vm.ip_address.mac_address, vm.kvm_hostname, vm.information.to_s].join(', ')
      vm.archive
      vm.ip_address.destroy
    end
  end

end
