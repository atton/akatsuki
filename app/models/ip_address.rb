class IpAddress < ActiveRecord::Base
  belongs_to :user
  has_one    :virtual_machine,          dependent: :destroy
  has_one    :radius_check_information, dependent: :destroy
  has_one    :radius_reply_information, dependent: :destroy
  has_many   :local_records,            dependent: :destroy

  validates_presence_of   :domain, :affiliation, :mac_address, :assigned_address
  validates_uniqueness_of :domain, scope: :affiliation
  validates_uniqueness_of :mac_address
  validates_uniqueness_of :assigned_address
  validates_inclusion_of  :affiliation,      in:      IEConfig::Domain::Affiliations.map(&:name) + ['os']
  validates_format_of     :assigned_address, with:    Resolv::IPv4::Regex
  validates_format_of     :mac_address,      with:    /\A([0-9a-f]{2}:){5}([0-9a-f]{2})\z/
  validates_format_of     :mac_address,      without: /00:00:00:00:00:00/

  before_validation ->() {self.mac_address = self.mac_address.gsub('-',':').downcase}
  before_validation :address_auto_assign, if: ->(){self.assigned_address.blank?}

  validate  :domain_format

  after_save :maintain_local_records
  after_save :maintain_radius_informations

  def private_address?
    assigned_address.start_with?('10.')
  end

  def flat_segment?
    IPAddr.new(IEConfig::VLAN::FlatSegment.ipv4).include? assigned_address
  end

  def modifiable_by_user?
    private_address? && virtual_machine.blank?
  end

  def affiliation_detail
    IEConfig::Domain::Affiliations.find{|a| a.name == self.affiliation}
  end

  def fqdn
    [domain, affiliation, IEConfig::Domain::Base].join('.')
  end

  def ipv4
    self.assigned_address
  end

  def rev4
    return '' if self.assigned_address.blank?
    IPAddr.new(ipv4).reverse
  end

  def ipv6
    return nil if self.mac_address.blank?

    v6 = local_records.find_by(rdtype: 'AAAA').try(:rdata)
    return v6 if v6.present?

    info = IEConfig::VLAN.find_info_by_vlan_id(vlan)
    # NetAddr::EUI64 has subeffect which break caller macaddress ......
    v6 = NetAddr::EUI64.create(self.mac_address.clone).to_ipv6(info.ipv6) if info.present?

    return v6
  rescue NetAddr::ValidationError => e
    return nil
  end

  def rev6
    IPAddr.new(self.ipv6).reverse if ipv6.present?
  end

  def address_auto_assign
    info = IEConfig::VLAN.find_info_by_vlan_id vlan
    return nil if info.blank?
    candidate_range = IPAddr.new(info.ipv4).to_range.drop(1)  # drop network address

    candidate_ip = candidate_range.find do |candidate|
      not IpAddress.exists?(assigned_address: candidate.to_s)
    end
    self.assigned_address = candidate_ip.try(:to_s)
  end

  def save_with_auto_assign count=0
    return false if count >= 100
    info      = IEConfig::Domain::Affiliations.find{|a| a.name == self.affiliation}
    self.vlan = info.default_vlan if info.present?

    return true  if save
    if errors.full_messages == ['Assigned address has already been taken']
      address_auto_assign
      save_with_auto_assign count.succ
      end
  rescue ActiveRecord::RecordNotUnique => e
    address_auto_assign
    save_with_auto_assign count.succ
  end

  def maintain_local_records
    return true unless flat_segment?
    return true if affiliation_detail.blank?
    a_record = local_records.find_or_create_by(rdtype: 'A')
    a_record.update_attributes(ttl: IEConfig::Domain::TTL, name: fqdn, rdata: self.ipv4)

    aaaa_record = local_records.find_or_create_by(rdtype: 'AAAA')
    aaaa_record.update_attributes(ttl: IEConfig::Domain::TTL, name: fqdn, rdata: self.ipv6)

    rev4_record = local_records.where(rdtype: 'PTR').find{|r| r.name.include?('addr')}
    rev4_record ||= local_records.new(rdtype: 'PTR')
    rev4_record.update_attributes(ttl: IEConfig::Domain::TTL, name: self.rev4, rdata: fqdn)

    rev6_record = local_records.where(rdtype: 'PTR').find{|r| r.name.include?('ip6')}
    rev6_record ||= local_records.new(rdtype: 'PTR')
    rev6_record.update_attributes(ttl: IEConfig::Domain::TTL, name: self.rev6, rdata: fqdn)

    [a_record, rev4_record, rev6_record].each(&:update_serial)
  end

  def maintain_radius_informations
    rad_check = radius_check_information || create_radius_check_information
    rad_check.mac_address = mac_address

    rad_reply = radius_reply_information || create_radius_reply_information
    rad_reply.mac_address = mac_address
    rad_reply.value       = assigned_address

    [rad_check, rad_reply].all?{|i| i.save}
  end

  def self.delete_candidates_without_vm
    all.includes(:user, :virtual_machine).select do |ip|
      ip.user.graduate? && ip.private_address? && ip.virtual_machine.blank?
    end
  end

  def self.delete_candidates_with_vm
    all.includes(:user, :virtual_machine).select do |ip|
      ip.user.graduate? && ip.private_address? && ip.virtual_machine.present?
    end
  end

  private

  def domain_format
    return false if domain.blank?

    if domain.include?('.')
      errors.add(:domain, 'ドメイン名に "." は使用できません。') and return false
    end
    unless fqdn =~ Regexp.new("^#{URI::REGEXP::PATTERN::HOSTNAME}$")
      errors.add(:domain, 'ドメイン名が不正です。詳細は下の説明をご覧ください。') and return false
    end
    return true
  end
end
