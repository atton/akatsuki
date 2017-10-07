class LDAP::Group < ActiveLdap::Base
  ldap_mapping dn_attribute: :cn, prefix: 'ou=Group', classes: ['top', 'posixGroup']
end
