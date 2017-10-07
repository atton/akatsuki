require 'rails_helper'

RSpec.describe VirtualMachine, type: :model do
  before(:each) do
    allow(IEConfig::KVM).to receive(:templates).and_return(['vol1']).twice
    Fog.mock!
    Fog.credentials = { libvirt_uri: 'qemu://libvirt/system' }.merge(Fog.credentials)
    IEConfig::KVM.connection  # Access to lazy load constants (e.g: Fog::Compute::Libvirt)
  end

  after(:each) do
    Fog::Mock.reset
  end

  describe 'template_name' do
    it 'has validation' do
      user = User.create(uid: 'hoge')

      classes = [IpAddress, VirtualMachine]
      old_counts = classes.map(&:count)

      vm = VirtualMachine.new
      expect(vm.save_from_submit_form(template_name: 'hoge', user_id: user.id,
                                      domain: 'nya', affiliation: 'st')).to be_falsy
      expect(vm.errors).to_not be_empty
      expect(vm.errors.has_key?(:template_name)).to be_truthy
      expect(classes.map(&:count)).to eq(old_counts)
    end
  end

  describe 'name' do
    it 'has validation' do
      user = User.create(uid: 'hoge')
      ip   = sample_ip_address
      expect(ip.save).to be_truthy

      classes = [IpAddress, VirtualMachine]
      old_counts = classes.map(&:count)

      vm = VirtualMachine.new
      expect(vm.save_from_submit_form(template_name: 'vol1', user_id: user.id,
                                      domain: ip.domain, affiliation: ip.affiliation)).to be_falsy
      expect(vm.errors).to_not be_empty
      expect(vm.errors.has_key?(:ip_address)).to be_truthy
      expect(classes.map(&:count)).to eq(old_counts)
    end
  end

  describe 'clone' do
    it 'with valid information' do
      user = User.create(uid: 'hoge')

      classes = [IpAddress, VirtualMachine]
      old_counts = classes.map(&:count)

      template_name = 'vol1'
      allow_any_instance_of(Fog::Compute::Libvirt::Volume).to receive(:clone_volume).
                            with('hoge(nya.st).qcow2', 'rental').and_return(1234)
      allow_any_instance_of(Fog::Compute::Libvirt::Servers).to receive(:create).
                            with(name: 'hoge(nya.st)', volumes: [1234],
                                 nics: [{bridge: 'br62', model: 'virtio'}], memory_size: anything).and_return(true)
      allow(IEConfig::KVM).to receive(:not_busy_hostname).and_return('poe')
      allow(IEConfig::KVM).to receive(:connection).with('poe').and_return(IEConfig::KVM::HostInformations.first.connection)


      vm = VirtualMachine.new
      allow(vm).to receive_message_chain(:vm_control, :nics, :first, :mac).and_return('33:44:55:66:77:88')
      expect(vm.save_from_submit_form(template_name: template_name, user_id: user.id,
                                      domain: 'nya', affiliation: 'st')).to be_truthy
      expect(vm.errors).to be_empty
      expect(vm.kvm_hostname).to eq('poe')
      expect(vm.ip_address.mac_address).to eq('33:44:55:66:77:88')
      expect(classes.map(&:count)).to eq(old_counts.map{|a| a.succ})
    end
  end

  describe 'migration from VMWare' do
    it 'can uses any name and template_name' do
      vm               = VirtualMachine.new
      vm.name          = 'VMWare22'
      vm.template_name = 'migrated'
      vm.kvm_hostname  = 'kvm-host'
      expect(vm.save).to be_truthy
      mock_kvm = spy('mock')
      allow(mock_kvm).to receive_message_chain(:servers, :find).and_return(666)
      allow(IEConfig::KVM).to receive(:connection).with('kvm-host').and_return(mock_kvm)
      expect(vm.send(:vm_control)).to eq(666)
    end
  end

  describe '#archive' do
    it 'clones volume to archive pool' do
      vm = VirtualMachine.new(name: 'hoge', template_name: 'fuga', kvm_hostname: 'piyo')
      expect(vm.save).to be_truthy

      vol = spy('vol')
      expect(vol).to receive(:name).and_return('aaa').once
      expect(vol).to receive(:clone_volume).with('aaa', 'archive').once
      expect(vol).to receive(:destroy).once
      expect_any_instance_of(VirtualMachine).to receive_message_chain(:vm_control, :volumes).and_return([vol])

      vm.archive
    end
  end
end
