class AddNamedViews < ActiveRecord::Migration
  # This migration creates views for named using bind-sdb-chroot.
  # You must create 'named' user before migration.
  # secondary DNS pulls all records in zone. So we split `local_records` table to each zone.

  Domains           = ['', 'st',  'ads', 'cr', 'dsp', 'engr', 'eva', 'fts', 'iip', 'lsi',
                       'ms', 'nal', 'nc', 'neo', 'pc', 'sip', 'sys', 'tea', 'ns']
  TopDomainViewName = 'ie'

  FoundationServerReverseV4 = '10.100.10.in-addr.arpa'
  FoundationServerReverseV6 = '0.0.5.a.c.1.0.0.8.f.2.0.1.0.0.2.ip6.arpa'

  def up
    # all domains
    Domains.each do |d|
      view_name = d.blank? ? TopDomainViewName : d
      domain    = d.blank? ? '' : d+'.'
      execute "create view #{view_name} as select name, ttl, rdtype, rdata from local_records where name ~ '^([^.]*\\.|)#{domain}ie.u-ryukyu.ac.jp';"
      execute "grant select on #{view_name} to named;"
    end

    # Flat Reverse v4
    16.times do |r|
      view_name = "rev4_flat_#{r}"
      execute ["create view #{view_name} as select name, ttl,rdtype, rdata from local_records",
               "where name ~ '^(\\d+\\.|)#{r}\\.0\\.10.in-addr.arpa';"].join(' ')
      execute "grant select on #{view_name} to named;"
    end

    # Flat Reverse v6
    [IEConfig::Domain::FlatSegmentRev6].each do |r|
      view_name = 'rev6_flat'
      execute "create view #{view_name} as select name, ttl,rdtype, rdata from local_records where name ~ '^.*#{r}';"
      execute "grant select on #{view_name} to named;"
    end

    # FoundationServer Reverse 4
    [FoundationServerReverseV4].each do |r|
      view_name = 'rev4_foundation'
      execute ["create view #{view_name} as select name, ttl,rdtype, rdata from local_records",
               "where name ~ '^(\\d+\\.|)10\\.100\\.10.in-addr.arpa';"].join(' ')
      execute "grant select on #{view_name} to named;"
    end

    # FoundationServer Reverse 6
    [FoundationServerReverseV6].each do |r|
      view_name = 'rev6_foundation'
      execute "create view #{view_name} as select name, ttl,rdtype, rdata from local_records where name ~ '^.*#{r}';"
      execute "grant select on #{view_name} to named;"
    end

    # GlobalIP Reverse v4
    [IEConfig::Domain::GlobalIPv4Reverse].each do |r|
      view_name = 'rev4_global'
      execute ["create view #{view_name} as select name, ttl,rdtype, rdata from local_records",
               "where name ~ '^(\\d+\\.|)50\\.13\\.133.in-addr.arpa';"].join(' ')
      execute "grant select on #{view_name} to named;"
    end

    # GlobalIP Reverse 6
    [IEConfig::Domain::GlobalIPv6Reverse].each do |r|
      view_name = 'rev6_global'
      execute "create view #{view_name} as select name, ttl,rdtype, rdata from local_records where name ~ '^.*#{r}';"
      execute "grant select on #{view_name} to named;"
    end

  end

  def down
    # all domains
    Domains.each do |d|
      view_name = d.blank? ? TopDomainViewName : d
      execute "revoke select on #{view_name} from named;"
      execute "drop view #{view_name};"
    end

    # Flat Reverse v4
    16.times do |r|
      view_name = "rev4_flat_#{r}"
      execute "revoke select on #{view_name} from named;"
      execute "drop view #{view_name};"
    end

   # Reverse  Flat v6, FoundationServer 4,6 , GlobalIP 4,6
   ['rev6_flat', 'rev4_foundation', 'rev6_foundation', 'rev4_global', 'rev6_global'].each do |v|
     execute "revoke select on #{v} from named;"
     execute "drop view #{v};"
   end
  end
end
