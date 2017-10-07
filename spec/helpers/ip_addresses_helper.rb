def sample_ip_address
  ip             = IpAddress.new
  ip.mac_address = 'ff:ff:ff:00:00:00'
  ip.domain      = 'hoge'
  ip.affiliation = 'st'
  return ip
end

def fill_sample_ip
  ip = sample_ip_address
  fill_in 'Mac address',  with: ip.mac_address
  fill_in 'Domain',       with: ip.domain
  select  ip.affiliation, from: 'Affiliation'
end
