require 'rails_helper'

describe 'Mail Notification' do
  it "don't send in IpAddress.create" do
    expect(sample_ip_address.save).to be_truthy
    expect(ActionMailer::Base.deliveries).to be_empty
  end

  describe 'in Web UI' do
    before(:each) do
      user, pass = user_information_by_role :student
      user_sign_in user, pass
      @user = User.find_by(uid: user)

      visit new_ip_address_path
      fill_sample_ip
      click_button 'Create Ip address'

      @ip   = IpAddress.find_by(sample_ip_address.attributes.select{|k,v| v.present?})
    end

    specify 'sent when create ip address' do
      expect(ActionMailer::Base.deliveries.size).to eq(1)
      mail = ActionMailer::Base.deliveries.first
      expect(mail.to).to       be_include(@user.ldap_user.mail)
      expect(mail.reply_to).to be_include('sys-admin@ie.u-ryukyu.ac.jp')
      expect(mail.from).to     be_include('sys-admin@ie.u-ryukyu.ac.jp')
      expect(mail.subject).to  be_include('IP作成')
      expect(mail.subject).to  be_include(@ip.fqdn)
      expect(mail.body).to     match(@ip.fqdn)
      expect(mail.body).to     match(@ip.ipv4)
      expect(mail.body).to     match(@ip.ipv6)
      expect(mail.body).to     match('DNS')
      expect(mail.body).to     match('10.100.10.10')
      expect(mail.body).to     match('10.0.15.254')
      expect(mail.body).to     match('2001:2f8:1c:a500::10')
      expect(mail.body).to     match('2001:2f8:1c:a504::1')
    end

    specify 'sent when update ip address' do
      expect(ActionMailer::Base.deliveries.size).to eq(1)
      visit edit_ip_address_path(@ip)

      fill_in      'Domain', with: 'fuga'
      click_button 'Update Ip address'
      expect(ActionMailer::Base.deliveries.size).to eq(2)
      @ip.reload
      expect(@ip.fqdn).to eq('fuga.st.ie.u-ryukyu.ac.jp')

      mail = ActionMailer::Base.deliveries.last
      expect(mail.to).to       be_include(@user.ldap_user.mail)
      expect(mail.reply_to).to be_include('sys-admin@ie.u-ryukyu.ac.jp')
      expect(mail.from).to     be_include('sys-admin@ie.u-ryukyu.ac.jp')
      expect(mail.subject).to  be_include('IP編集')
      expect(mail.subject).to  be_include(@ip.fqdn)
      expect(mail.body).to     match(@ip.fqdn)
      expect(mail.body).to     match(@ip.ipv4)
      expect(mail.body).to     match(@ip.ipv6)
      expect(mail.body).to     match('DNS')
      expect(mail.body).to     match('10.100.10.10')
      expect(mail.body).to     match('10.0.15.254')
      expect(mail.body).to     match('2001:2f8:1c:a500::10')
      expect(mail.body).to     match('2001:2f8:1c:a504::1')
    end

    specify 'sent when delete ip address' do
      expect(ActionMailer::Base.deliveries.size).to eq(1)
      visit edit_ip_address_path(@ip)

      click_button 'Delete IP'
      expect(ActionMailer::Base.deliveries.size).to eq(2)

      mail = ActionMailer::Base.deliveries.last
      expect(mail.to).to       be_include(@user.ldap_user.mail)
      expect(mail.reply_to).to be_include('sys-admin@ie.u-ryukyu.ac.jp')
      expect(mail.from).to     be_include('sys-admin@ie.u-ryukyu.ac.jp')
      expect(mail.subject).to  be_include('IP削除')
      expect(mail.subject).to  be_include(@ip.fqdn)
      expect(mail.body).to     match(@ip.fqdn)
      expect(mail.body).to     match(@ip.ipv4)
      expect(mail.body).to     match(@ip.ipv6)
      expect(mail.body).to_not match('DNS')
      expect(mail.body).to_not match('10.100.10.10')
      expect(mail.body).to_not match('10.0.15.254')
      expect(mail.body).to_not match('2001:2f8:1c:a500::10')
      expect(mail.body).to_not match('2001:2f8:1c:a504::1')

      expect(IpAddress.count).to be_zero
    end
  end

end
