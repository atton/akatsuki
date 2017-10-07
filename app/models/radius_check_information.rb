class RadiusCheckInformation < ActiveRecord::Base
  # Information for DHCP with FreeRadius in Akatsuki.
  # based on `radcheck` table.
  # http://wiki.freeradius.org/guide/dhcp-for-static-ip-allocation
  belongs_to :ip_address

  validates_presence_of   :mac_address, :radius_attribute, :op
  validates_uniqueness_of :mac_address
  validates_format_of     :mac_address, with:    /\A([0-9a-f]{2}:){5}([0-9a-f]{2})\z/
  validates_format_of     :mac_address, without: /00:00:00:00:00:00/
end
