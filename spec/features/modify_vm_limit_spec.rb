require 'rails_helper'

describe 'modify User#vm_limit' do

  specify 'cannot access without sign in' do
    visit syskan_users_path
    expect(current_path).to eq(sign_in_path)
  end

  specify 'cannot access non-syskan' do
    not_syskan = [:student, :teacher, :iesudoer]

    not_syskan.each do |user|
      user_sign_in_by_role user
      visit syskan_users_path
      expect(current_path).to eq(root_path)
    end
  end

  describe 'by syskan' do

    specify 'increment vm_limit' do
      uid, password  = user_information_by_role(:syskan)
      user_sign_in uid, password
      visit(root_path)
      expect(page).to_not have_content('New VM')

      visit syskan_users_path
      user = User.find_by(uid: uid)
      expect(user).to_not be_vm_creatable
      click_button '+'
      expect(User.find_by(uid: uid).vm_limit).to eq(user.vm_limit.succ)
      expect(User.find_by(uid: uid)).to be_vm_creatable

      visit(root_path)
      expect(page).to have_content('New VM')
    end

    specify 'decrement vm_limit' do
      user_sign_in_by_role :syskan
      visit syskan_users_path

      uid  = user_information_by_role(:syskan).first
      user = User.find_by(uid: uid)
      user.update_attributes(vm_limit: 10)

      click_button '-'
      expect(User.find_by(uid: uid).vm_limit).to eq(9)
    end

    specify 'decrement vm_limit to 0' do
      user_sign_in_by_role :syskan
      visit syskan_users_path

      uid  = user_information_by_role(:syskan).first
      user = User.find_by(uid: uid)
      user.update_attributes(vm_limit: 0)

      click_button '-'
      expect(User.find_by(uid: uid).vm_limit).to eq(0)
    end
  end

end

