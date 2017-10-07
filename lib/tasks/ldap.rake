namespace :ldap do

  desc 'Delete edy ids and omit sambaNTPassword of graduated users'
  task disable_graduated_users: :environment do
    LDAP::User.all.select(&:graduate?).each do |l|
      next if l.sambaNTPassword.blank? && l.ldapedyid.blank? && l.loginShell == '/bin/false'

      edyids                      = l.ldapedyid
      l.sambaNTPassword           = nil
      l.ldapedyid                 = nil
      l.loginShell                = '/bin/false'
      l.userPassword_confirmation = l.userPassword

      l.save!
      puts 'Account disabled: ' + l.uid.to_s + ', ' + edyids.to_s
    end
  end

end
