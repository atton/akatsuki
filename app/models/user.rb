class User < ActiveRecord::Base
  has_many :ip_addresses, dependent: :destroy

  def ldap_user
    @ldap_user ||= LDAP::User.find(uid)
  end

  [:syskan?, :graduate?, :iesudoer?].each do |group|
    define_method group, ->(){ldap_user.send(group)}
  end

  def virtual_machines
    ip_addresses.includes(:virtual_machine)
    ip_addresses.select{|s| s.virtual_machine.present? }
  end

  def vm_creatable?
    vm_limit > 0
  end

  def vm_controllable?
    virtual_machines.present?
  end
end
