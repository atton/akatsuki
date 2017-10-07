require 'rails_helper'

describe 'navbars' do

  specify 'non privileged user has not added toolbar' do
    user_sign_in_by_role(:student)
    visit index_path
    expect(page).to_not be_has_content('管理者メニュー')
    expect(page).to_not be_has_content('syskan')
  end

  specify 'iesudoers has added toolbar' do
    roles = [:iesudoer, :iesudoer_and_syskan]
    roles.each do |role|
      user_sign_in_by_role(role)
      visit index_path
      expect(page).to be_has_content('管理者メニュー')
    end
  end

  specify 'syskan has added toolbar' do
    roles = [:syskan, :iesudoer_and_syskan]
    roles.each do |role|
      user_sign_in_by_role(role)
      visit index_path
      expect(page).to be_has_content('syskan')
    end
  end

  specify 'syskan and iesudoer has both toolbar' do
    user_sign_in_by_role(:iesudoer_and_syskan)
    visit index_path
    expect(page).to be_has_content('syskan')
    expect(page).to be_has_content('管理者メニュー')
  end

end
