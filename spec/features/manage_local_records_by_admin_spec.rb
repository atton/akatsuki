require 'rails_helper'

describe 'manage local records by admin' do

  specify 'non-privileged users can not access' do
    roles = [:student, :syskan]

    roles.each do |role|
      user_sign_in_by_role role
      visit admin_local_records_path
      expect(current_path).to eq(root_path)
    end
  end

  specify 'privileged users can access' do
    roles = [:iesudoer_and_syskan, :iesudoer]

    roles.each do |role|
      user_sign_in_by_role role
      visit admin_local_records_path
      expect(current_path).to eq(admin_local_records_path)
    end
  end

  specify 'index has content' do
    user_sign_in_by_role :iesudoer
    visit admin_local_records_path
    expect(page).to be_has_content
  end

  describe '#new' do
    def fill_local_record
      user_sign_in_by_role :iesudoer
      visit new_admin_local_record_path

      fill_in 'Name',   with: 'aaa'
      fill_in 'Rdtype', with: 'MX'
      fill_in 'Rdata',  with: 'bbb'
      fill_in 'Ttl',    with: 100
    end

    specify 'admin can create local records with weak validation' do
      before_count = LocalRecord.count
      fill_local_record
      click_button 'Create Local record'

      expect(LocalRecord.count).to eq(before_count.succ)
    end

    specify 'weak validation is works' do
      before_count = LocalRecord.count

      fill_local_record
      fill_in 'Rdtype', with: 'nya'
      click_button 'Create Local record'

      expect(LocalRecord.count).to eq(before_count)
    end
  end

  describe '#edit' do
    before do
      @record = LocalRecord.create(name: 'hoge', rdtype: 'NS', rdata: 'aaa', ttl: 100)
    end

    specify 'record can edit' do
      user_sign_in_by_role :iesudoer
      visit edit_admin_local_record_path(@record)
      fill_in 'Name', with: 'fuga'
      click_button 'Update Local record'
      expect(@record.reload.name).to eq('fuga')
      expect(current_path).to eq(admin_local_records_path)
    end

    specify 'work with validation' do
      user_sign_in_by_role :iesudoer
      visit edit_admin_local_record_path(@record)
      fill_in 'Rdtype', with: ''
      click_button 'Update Local record'
      expect(@record.reload.rdtype).to eq('NS')
    end
  end

  describe '#destroy' do
    before do
      @record = LocalRecord.create(name: 'hoge', rdtype: 'NS', rdata: 'aaa', ttl: 100)
    end

    specify 'work with validation' do
      before_count = LocalRecord.count
      user_sign_in_by_role :iesudoer
      visit edit_admin_local_record_path(@record)
      click_button 'Delete Local record'
      expect(LocalRecord.exists?(id: @record.id)).to be_falsy
      expect(LocalRecord.count).to eq(before_count.pred)
    end
  end

end
