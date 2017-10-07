def operation_with_modify_ldap
  raise 'Please call with block' unless block_given?
  dumped_data = ActiveLdap::Base.dump(scope: :sub)

  yield
ensure
  ActiveLdap::Base.clear_active_connections!
  ActiveLdap::Base.delete_all(nil, scope: :sub)
  ActiveLdap::Base.load(dumped_data)
end
