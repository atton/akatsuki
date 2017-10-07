class AddJimView < ActiveRecord::Migration

  def up
    execute "create view jm as select name, ttl, rdtype, rdata from local_records where name ~ '^([^.]*\\.|)jm.ie.u-ryukyu.ac.jp';"
    execute 'grant select on jm to named';

    execute "create view rev4_jm as select name, ttl,rdtype, rdata from local_records where name ~ '^(\\d+\\.|)0\\.20\\.10.in-addr.arpa';"
    execute 'grant select on rev4_jm to named';

    execute "create view rev6_jm as select name, ttl, rdtype, rdata from local_records where name ~ '^.*0.1.5.a.c.1.0.0.8.f.2.0.1.0.0.2.ip6.arpa';"
    execute 'grant select on rev6_jm to named';

  end

  def down
    ['jm', 'rev4_jm', 'rev6_jm'].each do |v|
      execute "revoke select on #{v} from named;"
      execute "drop view #{v};"
    end
  end
end
