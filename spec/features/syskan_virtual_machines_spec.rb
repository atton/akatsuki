require 'rails_helper'

describe 'VLAN 51' do

  describe 'access permission' do

    specify 'allowed syskan' do
      roles = [:syskan, :iesudoer_and_syskan]

      roles.each do |role|
        user_sign_in_by_role role
        visit syskan_virtual_machines_path
        expect(current_path).to eq(syskan_virtual_machines_path)
        visit sign_out_path
      end
    end

    specify 'deny non-syskan users' do
      roles = [:student, :iesudoer]

      roles.each do |role|
        user_sign_in_by_role role
        visit syskan_virtual_machines_path
        expect(current_path).to eq(root_path)
        visit sign_out_path
      end
    end

  end
end
