require 'rails_helper'

describe 'iesudoer navbar' do

  it 'is contains admin links' do
    render partial: 'layouts/iesudoer_navbar'
    expect(rendered).to have_content('Create New LDAP User')
    expect(rendered).to have_content('Manage LocalRecords')
  end

end
