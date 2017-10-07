namespace :ip_address do

  desc 'Show list of delete candidates without VM'
  task show_delete_candidates_without_vm: :environment do
    ips  = IpAddress.delete_candidates_without_vm
    info = ips.map{|ip| [ip.user.uid, ip.fqdn, ip.mac_address, ip.assigned_address].join(",")}
    puts info.join("\n")
  end

  desc 'Delete IpAddresss of graduated users without VM'
  task delete_ips_of_graduated_users_without_vm: :environment do
    IpAddress.delete_candidates_without_vm.map(&:destroy)
  end
end
