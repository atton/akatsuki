require 'rails_helper'

describe 'add new user to LDAP' do
  specify 'cannot access without sign in' do
    visit new_ldap_user_path
    expect(current_path).to eq(sign_in_path)
  end

  specify 'cannot access by non privileged user' do
    non_privileged_users = [:student, :syskan]

    non_privileged_users.each do |user|
      user_sign_in_by_role user
      visit new_ldap_user_path
      expect(current_path).to eq(root_path)
    end
  end

  describe 'create ldap user' do
    def fill_user_information
      fill_in :user_uid,        with: 'hoge'
      fill_in :user_uidNumber , with: 100
      select  'その他',         from: :user_group
      fill_in :user_gecos,      with: 'hoge fuga'
      fill_in :user_cn,         with: 'ほげ ふが'
      fill_in :user_password,   with: 'password'
    end

    before do
      user_sign_in_by_role :iesudoer
      visit new_ldap_user_path
      fill_user_information
    end

    specify 'add accesible user by valid information' do
      number_of_users = LDAP::User.count

      operation_with_modify_ldap do
        click_button 'Save changes'
        expect(LDAP::User.count).to eq(number_of_users.succ)

        visit sign_out_path
        visit root_path
        expect(current_path).to eq(sign_in_path)
        user_sign_in('hoge', 'password')
        visit root_path
        expect(current_path).to eq(root_path)
      end
      expect(LDAP::User.count).to eq(number_of_users)
    end

    specify 'prevent create duplicate uid' do
      number_of_users = LDAP::User.count
      fill_in :user_uid,        with: 'akatsuki'

      operation_with_modify_ldap do
        click_button 'Save changes'
        expect(LDAP::User.count).to eq(number_of_users)
      end
    end

    specify 'prevent create duplicate uidNumber' do
      number_of_users = LDAP::User.count
      fill_in :user_uidNumber, with: 10000

      operation_with_modify_ldap do
        click_button 'Save changes'
        expect(LDAP::User.count).to eq(number_of_users)
      end
    end
  end

end
