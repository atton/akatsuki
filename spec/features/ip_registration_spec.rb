require 'rails_helper'

describe 'IP address registration' do
  describe 'all roles can register' do
    def can_create_ip role
      user_sign_in_by_type role
      visit new_ip_address_path
      expect(current_path).to eq(new_ip_address_path)
      fill_sample_ip
      count = IpAddress.count
      click_button 'Create Ip address'
      expect(IpAddress.count).to eq(count.succ)
    end

    specify 'student' do can_create_ip :student end
    specify 'teacher' do can_create_ip :teacher end
    specify 'other'   do can_create_ip :other   end
    specify 'adjunct' do can_create_ip :adjunct end
  end

  specify 'cannot modify affiliation after first registration' do
    user_sign_in_by_type :student
    visit new_ip_address_path
    fill_sample_ip
    before_ips = IpAddress.all.to_a
    click_button 'Create Ip address'
    created_ip = (IpAddress.all - before_ips).first
    visit edit_ip_address_path(created_ip)
    has_no_select? 'Affiliation'
  end

  describe 'edit permission' do
    specify 'allowed to flat IP' do
      user_sign_in_by_type :student
      visit new_ip_address_path
      fill_sample_ip
      fill_in 'Domain', with: 'ns'
      before_ips = IpAddress.all.to_a
      click_button 'Create Ip address'
      created_ip = (IpAddress.all - before_ips).first
      visit ip_address_path(created_ip)
      expect(page).to be_has_content('Edit IP')
      visit edit_ip_address_path(created_ip)
      expect(current_path).to eq(edit_ip_address_path(created_ip))
    end

    specify 'allowed to private IP' do
      user_sign_in_by_type :student
      visit new_ip_address_path
      fill_sample_ip
      before_ips = IpAddress.all.to_a
      click_button 'Create Ip address'
      created_ip = (IpAddress.all - before_ips).first
      visit ip_address_path(created_ip)
      expect(page).to be_has_content('Edit IP')
      visit edit_ip_address_path(created_ip)
      expect(current_path).to eq(edit_ip_address_path(created_ip))
    end

    specify 'not allowed to Global IP' do
      information = user_information_by_role :student
      user_sign_in *information
      ip                  = sample_ip_address
      ip.assigned_address = '133.13.40.50'
      ip.user             = User.last
      expect(ip.save).to be_truthy
      visit ip_address_path(ip)
      expect(page).to_not be_has_content('Edit IP')
      visit edit_ip_address_path(ip)
      expect(current_path).to_not be(edit_ip_address_path(ip))
      expect(current_path).to     eq(root_path)
    end
  end

  specify 'access to IP of another person' do
    user_sign_in_by_type :student
    visit new_ip_address_path
    fill_sample_ip
    click_button 'Create Ip address'
    ip = IpAddress.last
    visit ip_address_path(ip)
    expect(current_path).to eq(ip_address_path(ip))
    visit sign_out_path

    user_sign_in_by_type :teacher
    visit ip_address_path(ip)
    expect(current_path).to_not be(ip_address_path(ip))
    expect(current_path).to     eq(root_path)
  end


  specify 'supports concurrent requests' do
    # This test not passed on SQLite3
    before_ip_numbers  = IpAddress.count
    number_of_requests = 15
    requests = number_of_requests.times.map do |n|
      fork do
        user_sign_in_by_uid :akatsuki
        visit new_ip_address_path
        expect(new_ip_address_path)
        fill_in 'Mac address', with: "00:11:22:33:44:#{format('%02x', n).upcase}"
        fill_in 'Domain',      with: "hoge#{n}"
        select  'st',          from: 'Affiliation'
        click_button 'Create Ip address'
      end
    end

    results = requests.map do |pid|
      Process.waitpid(pid)
      $?.exitstatus
    end
    ActiveRecord::Base.clear_active_connections!
    expect(IpAddress.count).to eq(before_ip_numbers+number_of_requests)
  end
end

