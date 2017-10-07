require 'rails_helper'

describe 'modify LDAP infomation' do

  describe 'permission' do

    specify 'cant access without sign in' do
      visit edit_ldap_user_path
      expect(current_path).to eq(sign_in_path)
    end

    specify 'student user has not password field' do
      types = [:student]
      types.each do |type|
        user_sign_in_by_type type
        visit edit_ldap_user_path
        expect(page).not_to be_has_field(:attributes_userPassword)
        expect(page).not_to be_has_field(:attributes_userPassword_confirmation)
        expect(page).not_to be_has_field(:attributes_current_password)
      end
    end

    specify 'teacher/adjunct/other user has password field' do
      types = [:teacher, :adjunct, :other]
      types.each do |type|
        user_sign_in_by_type type
        visit edit_ldap_user_path
        expect(page).to be_has_field(:attributes_userPassword)
        expect(page).to be_has_field(:attributes_userPassword_confirmation)
        expect(page).to be_has_field(:attributes_current_password)
      end
    end
  end

  describe 'function' do

    before do
      stub_const "IEConfig::LDAP::EdyDevices", {"hoge"=>"0.0.0.0"}
      stub_const "IEConfig::LDAP::Timeout", 1
    end

    specify 'loginShell' do
      user_sign_in_by_role :student
      visit edit_ldap_user_path
      info = user_information_by_role :student

      operation_with_modify_ldap do
        expect(LDAP::User.find(info.first).loginShell).to eq('/bin/bash')
        select '/bin/zsh', from: :attributes_loginShell
        click_button '変更する'
        expect(LDAP::User.find(info.first).loginShell).to eq('/bin/zsh')
      end
    end

    specify 'valid password' do
      types = [:teacher, :adjunct, :other]

      types.each do |type|
        info = user_information_by_type type
        user_sign_in_by_type type
        visit edit_ldap_user_path

        operation_with_modify_ldap do
          fill_in :attributes_userPassword, with: 'password'
          fill_in :attributes_userPassword_confirmation, with: 'password'
          fill_in :attributes_current_password, with: info.last
          click_button '変更する'

          visit sign_out_path
          visit root_path
          expect(current_path).to eq(sign_in_path)

          user_sign_in info.first, 'password'
          visit root_path
          expect(current_path).to eq(root_path)
        end
      end
    end

    specify 'invalid confirm password' do
      types = [:teacher, :adjunct, :other]

      types.each do |type|
        info = user_information_by_type type
        user_sign_in_by_type type
        visit edit_ldap_user_path

        operation_with_modify_ldap do
          fill_in :attributes_userPassword, with: 'password'
          fill_in :attributes_userPassword_confirmation, with: 'invalid'
          fill_in :attributes_current_password, with: info.last
          click_button '変更する'

          visit sign_out_path
          visit root_path
          expect(current_path).to eq(sign_in_path)

          user_sign_in info.first, 'password'
          visit root_path
          expect(current_path).to eq(sign_in_path)
        end
      end
    end

    specify 'invalid current password' do
      types = [:teacher, :adjunct, :other]

      types.each do |type|
        info = user_information_by_type type
        user_sign_in_by_type type
        visit edit_ldap_user_path

        operation_with_modify_ldap do
          fill_in :attributes_userPassword, with: 'password'
          fill_in :attributes_userPassword_confirmation, with: 'password'
          fill_in :attributes_current_password, with: 'invalid'
          click_button '変更する'

          visit sign_out_path
          visit root_path
          expect(current_path).to eq(sign_in_path)

          user_sign_in info.first, 'password'
          visit root_path
          expect(current_path).to eq(sign_in_path)
        end
      end
    end
  end
end
