require 'rails_helper'

describe 'syskan navbar' do

  it 'is contains syskan links' do
    render partial: 'layouts/syskan_navbar'
    expect(rendered).to have_content('VM Permissions')
    expect(rendered).to have_content('VM List')
    expect(rendered).to have_content('VLAN51 Control')
  end

end
