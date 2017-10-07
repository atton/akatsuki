require 'rails_helper'

describe 'routing' do

  specify 'get request to invalid URI when not signed in' do
    invalid_uris = ['hoge', '///', '**/', '/ip_addresses/100', '/ip_addresses/hoge']

    invalid_uris.each do |uri|
      visit uri
      expect(current_path).to eq(sign_in_path)
    end
  end

  specify 'get request to invalid URI when not signed in' do
    user_sign_in_by_role :student

    invalid_uris = ['hoge', '///', '**/', '/ip_addresses/100', '/ip_addresses/hoge']

    invalid_uris.each do |uri|
      visit uri
      expect(page).to be_has_content('Akatsuki')  # Show root_path
    end
  end

  specify 'handle internal server error' do
    user_sign_in_by_role :student
    visit new_ip_address_path
    expect(current_path).to eq(new_ip_address_path)
    allow(IpAddress).to receive(:new).and_raise(SyntaxError)
    visit new_ip_address_path
    expect(current_path).to eq(root_path)
    expect(page).to be_has_content('Syntax')
  end
end
