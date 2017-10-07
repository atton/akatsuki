require 'rails_helper'

describe 'create VM in kvm' do
  before(:each) do
    Fog.mock!
    Fog::Mock.reset
    IEConfig::KVM.connection  # Access to lazy load constants (e.g: Fog::Compute::Libvirt)
  end

  def sign_in_student_with_permission
    user_sign_in_by_role :student
    user = User.find_by(uid: user_information_by_role(:student).first)
    user.update_attributes!(vm_limit: user.vm_limit.succ)
    return user
  end

  describe 'User permission check' do
    before do
      user_sign_in_by_role :student
      @user = User.find_by(uid: user_information_by_role(:student).first)
    end

    describe 'vm_creatable?' do
      it "if user don't have vm_limit, user can't create VM" do
        expect(@user).to_not be_vm_creatable
        ip = @user.ip_addresses.new(domain: 'hoge', affiliation: 'st', mac_address: '00:11:22:33:44:55')
        ip.create_virtual_machine(template_name: 'none', name: 'hoge-st', kvm_hostname: 'fuga')
        expect(@user).to_not be_vm_creatable
      end
    end
    describe 'vm_controllable?' do
      it "if user have vm_limit, user can't control VM" do
        expect(@user).to_not be_vm_controllable
        @user.update_attributes!(vm_limit: 1)
        expect(@user).to_not be_vm_controllable
      end

      it "if user have VM, user can control VM" do
        expect(@user).to_not be_vm_controllable
        ip = @user.ip_addresses.new(domain: 'hoge', affiliation: 'st', mac_address: '00:11:22:33:44:55')
        ip.create_virtual_machine(template_name: 'none', name: 'hoge-st', kvm_hostname: 'fuga')
        expect(@user).to be_vm_controllable
        @user.update_attributes!(vm_limit: 1)
        expect(@user).to be_vm_controllable
      end
    end

  end

  specify 'not vm creatable user has not new_virtual_machine_path' do
    uid, pass = user_information_by_role :student
    user_sign_in uid, pass
    user = User.find_by(uid: uid)
    expect(user.vm_creatable?).to    be_falsy
    expect(user.vm_controllable?).to be_falsy
    visit root_path
    expect(page).to_not have_content('New VM')
  end

  specify 'vm creatable user has new_virtual_machine_path' do
    user = sign_in_student_with_permission
    expect(user.vm_creatable?).to    be_truthy
    expect(user.vm_controllable?).to be_falsy
    visit root_path
    expect(page).to have_link('New VM')
  end

  describe 'create vm uses form' do
    before :each do
      allow(IEConfig::KVM).to receive(:templates).and_return(['vol1'])
    end

    specify 'has validation' do
      user = sign_in_student_with_permission
      visit new_virtual_machine_path

      user.ip_addresses.create(domain: 'hoge', affiliation: 'st', mac_address: '00:11:22:33:44:55')
      old_count = IpAddress.count

      fill_in 'virtual_machine_domain',  with: 'hoge'
      select  'st',                      from: 'virtual_machine_affiliation'
      select  'vol1',                    from: 'virtual_machine_template_name'
      click_button 'Save changes'

      expect(IpAddress.count).to eq(old_count)
      expect(ActionMailer::Base.deliveries.size).to be_zero
    end

    specify 'clone vm' do
      user = sign_in_student_with_permission
      expect(user.vm_creatable?).to    be_truthy
      expect(user.vm_controllable?).to be_falsy
      expect(user.vm_limit).to be > 0
      visit root_path
      expect(page).to have_content('New VM')
      expect(page).to have_content('Virtual Machines')
      visit new_virtual_machine_path

      old_count = IpAddress.count

      fill_in 'virtual_machine_domain', with: 'nya'
      select  'st',                     from: 'virtual_machine_affiliation'
      select  'vol1',                   from: 'virtual_machine_template_name'

      allow_any_instance_of(Fog::Compute::Libvirt::Volume).to receive(:clone_volume).
                            with("#{user.uid}(nya.st).qcow2", 'rental').and_return(9876)
      allow_any_instance_of(Fog::Compute::Libvirt::Servers).to receive(:create).
                            with(name: "#{user.uid}(nya.st)", volumes: [9876],
                                 nics: [{bridge: 'br62', model: 'virtio'}], memory_size: anything).and_return(true)
      allow_any_instance_of(VirtualMachine).to receive_message_chain(:vm_control, :nics, :first, :mac).
                                                                     and_return('aa:bb:cc:dd:ee:ff')

      # clone from submit_form
      click_button 'Save changes'
      user.reload
      expect(current_path).to eq(root_path)
      expect(IpAddress.count).to eq(old_count.succ)
      expect(user.ip_addresses.any?{|ip| ip.virtual_machine.present?}).to be_truthy
      expect(user.ip_addresses.last.mac_address).to eq('aa:bb:cc:dd:ee:ff')
      expect(user.vm_creatable?).to    be_falsy
      expect(user.vm_controllable?).to be_truthy
      expect(user.vm_limit).to be_zero

      # cannot edit ip has virtual machine
      visit ip_address_path(user.ip_addresses.last)
      expect(page).to_not be_has_content('Edit IP')
      visit edit_ip_address_path(user.ip_addresses.last)
      expect(current_path).to_not eq(edit_ip_address_path(user.ip_addresses.last))
      expect(current_path).to     eq(root_path)

      # If reaches vm_limit to 0, cannot create VM
      expect(page).to have_content('Virtual Machines')
      expect(page).to_not be_has_content('New VM')
      visit new_virtual_machine_path
      expect(current_path).to eq(root_path)

      # User has notification email
      expect(ActionMailer::Base.deliveries.size).to eq(1)
      mail = ActionMailer::Base.deliveries.first
      expect(mail.to).to       be_include(user.ldap_user.mail)
      expect(mail.reply_to).to be_include('sys-admin@ie.u-ryukyu.ac.jp')
      expect(mail.from).to     be_include('sys-admin@ie.u-ryukyu.ac.jp')
      expect(mail.subject).to  be_include('IP作成')
      expect(mail.subject).to  be_include('nya.st.ie.u-ryukyu.ac.jp')
      expect(mail.body).to     match('aa:bb:cc:dd:ee:ff')
    end
  end
end
