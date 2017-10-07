require 'rails_helper'

describe 'sign in' do
  specify 'redirect to new session path when not signed in' do
    visit index_path
    expect(current_path).to eq(sign_in_path)
  end

  specify 'student can sign in' do
    types = [:student, :adjunct, :teacher, :other]

    types.each do |type|
      visit sign_in_path
      info = user_information_by_type(type)
      fill_in :uid,      with: info.first
      fill_in :password, with: info.last
      click_button 'Sign in'
      expect(current_path).to eq(root_path)
    end
  end

  specify 'graduate can not sign in' do
    visit sign_in_path
    info = user_information_by_type(:graduate)
    fill_in :uid,      with: info.first
    fill_in :password, with: info.last
    click_button 'Sign in'
    expect(current_path).not_to eq(root_path)
  end

  specify 'can another user sign in' do
    visit sign_in_path
    user_sign_in_by_role(:student)
    expect(current_path).to eq(root_path)
    visit syskan_users_path
    expect(current_path).to eq(root_path)
    visit sign_out_path
    user_sign_in_by_role(:syskan)
    expect(current_path).to eq(root_path)
    visit syskan_users_path
    expect(current_path).to eq(syskan_users_path)
  end
end
