class AddIisAndEduDomain < ActiveRecord::Migration
  def up
    ['edu', 'iis'].each do |v|
      execute "create view #{v} as select name, ttl, rdtype, rdata from local_records where name ~ '^([^.]*\\.|)#{v}.ie.u-ryukyu.ac.jp';"
      execute "grant select on #{v} to named";
    end
  end

  def down
    ['edu', 'iis'].each do |v|
      execute "revoke select on #{v} from named;"
      execute "drop view #{v};"
    end
  end
end
