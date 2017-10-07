class VirtualMachine < ActiveRecord::Base
  belongs_to :ip_address

  validates_presence_of   :name, :kvm_hostname
  validates_uniqueness_of :name

  def save_from_submit_form submit_params
    if IEConfig::KVM.templates.find{|s| s == submit_params[:template_name]}.blank?
      errors.add(:template_name, 'template missing') and return false
    end

    user       = User.find(submit_params[:user_id])
    ip         = user.ip_addresses.new(affiliation: submit_params[:affiliation],
                                       domain:      submit_params[:domain], mac_address: random_mac)

    unless ip.save_with_auto_assign
      errors.add(:ip_address, ip.errors.full_messages.join("\n")) and return false
    end
    self.ip_address = ip
    self.update_attributes!(name: vm_name, kvm_hostname: IEConfig::KVM.not_busy_hostname,
                            template_name: submit_params[:template_name])
    vm_create
    self.ip_address.update_attributes!(mac_address: vm_control.nics.first.mac)

    return true
  rescue => e
    ip_address.try(:destroy)
    errors.add(:vm, e.message) and return false
  end

  def archive
    vm_control.volumes.each do |v|
      v.clone_volume(v.name, IEConfig::KVM::ArchivePoolName)
      v.destroy
    end
  end

  def vm_name
    return nil if ip_address.blank?
    [ ip_address.try(:user).try(:uid),
     '(', ip_address.domain, '.', ip_address.affiliation, ')'].join
  end

  def volume_name
    [self.vm_name, IEConfig::KVM::Format].join('.')
  end

  def information
    vm = vm_control
    {
      cpus: vm.cpus,
      memory_size: vm.max_memory_size,
      volume_size: vm.volumes.first.capacity,
      is_active: vm.active?
    }
  end

  def power_on
    vm_control.start
  end

  def power_off
    vm_control.halt
  end

  def active?
    vm_control.active?
  end

  private

  def vm_control
    kvm = IEConfig::KVM.connection(kvm_hostname)
    kvm.servers.find{|s| s.name == self.name}
  end

  def vm_create
    kvm        = IEConfig::KVM.connection(kvm_hostname)
    vol        = kvm.volumes.find{|s| s.name == template_name}
    cloned_vol = vol.clone_volume(volume_name, IEConfig::KVM::PoolName)
    server     = kvm.servers.create(name: vm_name, volumes: [cloned_vol],
                                    nics: [{bridge: IEConfig::KVM::FlatBridge, model: IEConfig::KVM::BridgeModel}],
                                    memory_size: IEConfig::KVM::DefaultMemorySize)
  end

  def vm_delete
    vm = vm_control
    vm.try(:volumes).try(:each, &:destroy)
    vm.try(:destroy)
  end

  def random_mac
    random_mac = 6.times.map{format '%02x', (0..255).to_a.sample}.join(':') # FIXME: improve
  end
end
