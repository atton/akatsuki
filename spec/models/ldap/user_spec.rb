require 'rails_helper'

RSpec.describe 'LDAP::User' do
  before(:all) do
    @info = user_information_by_type :teacher
  end
  before(:each) do
    @user = LDAP::User.find(@info.first)
    stub_const "IEConfig::LDAP::EdyDevices", {}
  end

  describe '#notice_from_changes' do
    it 'shows modified attibutes' do
      @user.loginShell = 'aaa'
      expect(@user.notice_from_changes).to include('ログイン')

      @user.ldapedyid = ['aaa', 'bbb']
      expect(@user.notice_from_changes).to include('ログイン')
      expect(@user.notice_from_changes).to include('Edy')

      @user.userPassword = 'ccc'
      expect(@user.notice_from_changes).to include('ログイン')
      expect(@user.notice_from_changes).to include('Edy')
      expect(@user.notice_from_changes).to include('パスワード')
    end

    it "returns message if attibutes don't changed" do
      expect(@user.notice_from_changes).to include('ありません')
    end
  end

  describe '#set_attributes_from_form_parameters' do
    before do
      @uid        = 'hoge'
      @params     = {
        uid:        @uid,
        uidNumber:  9999,
        group:     'teacher',
        gecos:     'HOGE',
        cn:        'ほげ',
        password:  'PASSWORD',
      }
        @user       = LDAP::User.new
        @user_count = LDAP::User.all.count
    end

    it 'automatically generates mail attribute' do

      operation_with_modify_ldap do
        @user.set_attributes_from_form_parameters(@params)
        expect(@user.save).to be_truthy
        expect(LDAP::User.all.count).to eq(@user_count.succ)
        expect(@user.mail).to be_present
        expect(@user.mail).to eq('hoge@ie.u-ryukyu.ac.jp')
      end
    end

  end

  describe 'set_passwords_from_form_parameters' do
    it "don't changes userPassword if confirmation is missed" do
      operation_with_modify_ldap do
        @user.set_passwords_from_form_parameters({userPassword: 'aaa', userPassword_confirmation: 'aba',
                                                  current_password: @info.last})
        expect(@user.save).to be_falsy
        expect(@user.errors.full_messages).to include(/doesn't match/)
      end
    end

    it "don't changes userPassword if current password was missed" do
      operation_with_modify_ldap do
        expect{@user.set_passwords_from_form_parameters({userPassword: 'bbb', userPassword_confirmation: 'bbb',
                                                        current_password: 'gagaga'})}
        raise_error(RuntimeError, /パスワード入力が間違っています/)
      end
    end

    it "changes userPassword with valid confirmation and current password" do
      operation_with_modify_ldap do
        @user.set_passwords_from_form_parameters({userPassword: '111', userPassword_confirmation: '111',
                                                  current_password: @info.last})
        expect(@user.save).to be_truthy
        expect(@user.userPassword).to eq(ActiveLdap::UserPassword.md5('111'))
      end
    end

    it 'changes SambaNTHash' do
      operation_with_modify_ldap do
        old_hash = @user.sambaNTPassword
        @user.set_passwords_from_form_parameters({userPassword: '111', userPassword_confirmation: '111',
                                                  current_password: @info.last})
        expect(@user.save).to be_truthy
        expect(@user.sambaNTPassword).to_not eq(old_hash)
        expect(@user.sambaNTPassword).to eq(Smbhash.ntlm_hash('111'))
      end
    end

    it "don't changes SambaNTHash if modification of password was missed" do
      operation_with_modify_ldap do
        old_hash = @user.sambaNTPassword
        @user.set_passwords_from_form_parameters({userPassword: '111', userPassword_confirmation: '121',
                                                  current_password: @info.last})
        expect(@user.save).to be_falsy
        expect(@user.errors.full_messages).to include(/doesn't match/)
        expect(@user.sambaNTPassword).to eq(old_hash)
      end
    end
  end
end

