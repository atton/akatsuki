# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)

# ie.u-ryukyu.ac.jp
# NS Records
IEConfig::Domain::NS.each do |ns|
  LocalRecord.find_or_create_by(name: IEConfig::Domain::Base, rdtype: 'NS', rdata: ns)
end
# SOA Record
soa = LocalRecord.find_or_create_by(name: IEConfig::Domain::Base, rdtype: 'SOA')
soa.update_serial if soa.id.blank? || soa.rdata.blank?
# Rev NS Records
IEConfig::Domain::NS.each do |ns|
  LocalRecord.find_or_create_by(name: IEConfig::Domain::FoundationServerIPv4Reverse, rdtype: 'NS', rdata: ns)
  LocalRecord.find_or_create_by(name: IEConfig::Domain::FoundationServerIPv6Reverse, rdtype: 'NS', rdata: ns)
  LocalRecord.find_or_create_by(name: IEConfig::Domain::GlobalIPv4Reverse, rdtype: 'NS', rdata: ns)
  LocalRecord.find_or_create_by(name: IEConfig::Domain::GlobalIPv6Reverse, rdtype: 'NS', rdata: ns)
end
# Rev SOA Records
[ IEConfig::Domain::FoundationServerIPv4Reverse, IEConfig::Domain::FoundationServerIPv6Reverse,
  IEConfig::Domain::GlobalIPv4Reverse,           IEConfig::Domain::GlobalIPv6Reverse ].each do |rev|
  soa = LocalRecord.find_or_create_by(name: rev, rdtype: 'SOA')
  soa.update_serial if soa.id.blank? || soa.rdata.blank?
end

# sub domains
# Initialize NS/SOA for sub domains
IEConfig::Domain::Affiliations.each do |affiliation|
  # NS Records
  IEConfig::Domain::NS.each do |ns|
    # sub domain
    LocalRecord.find_or_create_by(name: affiliation.fqdn, rdtype: 'NS', rdata: ns)
    # in-addr(IPv4)
    LocalRecord.find_or_create_by(name: affiliation.rev4, rdtype: 'NS', rdata: ns)
    # in-addr(IPv6)
    LocalRecord.find_or_create_by(name: affiliation.rev6, rdtype: 'NS', rdata: ns)
  end

  # SOA Records
  [:fqdn, :rev4, :rev6].each do |type|
    soa = LocalRecord.find_or_create_by(name: affiliation.send(type), rdtype: 'SOA')
    soa.update_serial if soa.id.blank? || soa.rdata.blank?
  end
end

# Flat Reverse (1.0.10.in-addr.arpa - 15.0.10.in-addr.arpa)
IEConfig::Domain::FlatSegmentIPv4Reverses.each do |rev|
  IEConfig::Domain::NS.each do |ns|
    LocalRecord.find_or_create_by(name: rev, rdtype: 'NS', rdata: ns)
  end
  soa = LocalRecord.find_or_create_by(name: rev, rdtype: 'SOA')
  soa.update_serial if soa.id.blank? || soa.rdata.blank?
end


# FoundationServers (A, AAAA, PTR)
IEConfig::Domain::FoundationServerInformations.each do |host, ip|
  ipv4 = IPAddr.new(IEConfig::Domain::FoundationServerIPv4Prefix+ip.to_s)
  ipv6 = IPAddr.new(IEConfig::Domain::FoundationServerIPv6Prefix+ip.to_s)
  fqdn =  [host.to_s, IEConfig::Domain::Base].join('.')
  LocalRecord.find_or_create_by(name: fqdn,         rdtype: 'A',    rdata: ipv4.to_s)
  LocalRecord.find_or_create_by(name: ipv4.reverse, rdtype: 'PTR',  rdata: fqdn)
  LocalRecord.find_or_create_by(name: fqdn,         rdtype: 'AAAA', rdata: ipv6.to_s)
  LocalRecord.find_or_create_by(name: ipv6.reverse, rdtype: 'PTR',  rdata: fqdn)
end

