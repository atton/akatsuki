require 'rails_helper'

describe 'rake db:seed' do
  before do
    load Rails.root.join('db', 'seeds.rb')
  end

  it 'is insert all DNS information (NS/SOA)' do
    expect(LocalRecord.exists?(rdtype: 'SOA', name: 'ie.u-ryukyu.ac.jp')).to be_truthy  # SOA
    expect(LocalRecord.exists?(rdtype: 'NS',  name: 'ie.u-ryukyu.ac.jp')).to be_truthy  # NS

    IEConfig::Domain::Affiliations.each do |a|
      expect(LocalRecord.exists?(rdtype: 'SOA', name: a.fqdn)).to be_truthy  # SOA
      expect(LocalRecord.exists?(rdtype: 'NS',  name: a.fqdn)).to be_truthy  # NS

      expect(LocalRecord.exists?(rdtype: 'SOA', name: a.rev4)).to be_truthy  # SOA (rev4)
      expect(LocalRecord.exists?(rdtype: 'NS',  name: a.rev4)).to be_truthy  # NS  (rev4)

      expect(LocalRecord.exists?(rdtype: 'SOA', name: a.rev6)).to be_truthy  # SOA (rev6)
      expect(LocalRecord.exists?(rdtype: 'NS',  name: a.rev6)).to be_truthy  # NS  (rev6)
    end
  end

  describe 'idempotency' do
    it 'is not update rdata and updated_at' do
      before_records = LocalRecord.order(:id).to_a.map{|a| [a.rdata, a.updated_at]}
      expect(before_records).to_not be_empty

      load Rails.root.join('db', 'seeds.rb')
      expect(LocalRecord.order(:id).to_a.map{|a| [a.rdata, a.updated_at]}).to eq(before_records)
    end
  end

end
