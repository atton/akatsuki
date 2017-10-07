class AddVlanToIpAddress < ActiveRecord::Migration
  def up
    add_column :ip_addresses, :vlan, :integer, null:false, default: IEConfig::VLAN::FlatSegment.vlan_id

    ActiveRecord::Base.transaction do
      RadiusReplyInformation.destroy_all
      flat_range = IPAddr.new(IEConfig::VLAN::FlatSegment.ipv4)
      IpAddress.all.each do |ip|
        ip.vlan = ip.assigned_address.split('.')[2] unless flat_range.include?(ip.assigned_address)
        ip.maintain_radius_informations
        ip.save!
      end
    end
  rescue => e
    binding.pry
  end

  def down
    remove_column :ip_addresses, :vlan
      RadiusReplyInformation.destroy_all
      IpAddress.all.each(&:maintain_radius_informations)
  rescue => e
    binding.pry
  end
end
