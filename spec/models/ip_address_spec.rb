require 'rails_helper'

RSpec.describe IpAddress, type: :model do

  it 'is can create without Seed LocalRecords' do
    expect(LocalRecord.count).to eq(0)
    expect(sample_ip_address.save).to be_truthy
  end

  describe 'domain' do
    it 'is accept only numeric/alphabet characters and hyphen' do
      bad_domains = ['',  'hoge@', 'hoge.fuga' ',', '!']
      ip          = sample_ip_address

      bad_domains.each do |domain|
        ip.domain = domain
        expect(ip.save).to be_falsy
      end
    end
  end


  describe 'fqdn' do
    it 'is validated by URI::REGEXP::PATTERN::HOSTNAME' do
      bad_domains  = ['a-', '-a', 'hoge_fuga']
      good_domains = ['a', '900', 'hoge-puyo', 'hoge-puyo33']

      bad_domains.each do |domain|
        ip        = sample_ip_address
        ip.domain = domain
        expect(ip.save).to be_falsy
      end

      good_domains.each do |domain|
        ip        = sample_ip_address
        ip.domain = domain
        expect(ip.save).to    be_truthy
        expect(ip.destroy).to be_truthy
      end
    end
  end

  describe 'assigned_address' do
    it 'is resue released IP' do
      record_num = IpAddress.count
      number_of_samples = 5
      ips = number_of_samples.times.map do |n|
        IpAddress.new(mac_address: "01:00:00:00:00:0#{n.to_s}",
                      domain: "hoge#{n.to_s}", affiliation: 'st')
      end
      ips.each(&:save)
      expect(IpAddress.count).to eq(record_num+number_of_samples)

      sample        = ips.sample
      reuse_address = sample.assigned_address
      sample.destroy
      expect(IpAddress.count).to eq(record_num+number_of_samples-1)
      new_ip = IpAddress.new(mac_address: 'ff:ee:dd:cc:bb:aa', domain: 'aaaa', affiliation: 'st')
      expect(new_ip.save).to be_truthy
      expect(new_ip.assigned_address).to eq(reuse_address)
      expect(IpAddress.count).to eq(record_num+number_of_samples)
    end
  end

  describe 'ipv6' do
    it 'return nil when invalid vlan id' do
      ip = sample_ip_address
      ip.vlan = 1111
      expect(ip.ipv6).to be_nil
    end

    it 'return nil when invalid mac address' do
      ip = sample_ip_address
      ip.mac_address = 'aaa'
      expect(ip.ipv6).to be_nil
    end
  end

  describe 'affiliation' do
    it 'rejects invalid affiliation' do
      ip             = sample_ip_address
      ip.affiliation = 'aaa'
      expect(ip.save).to be_falsy
    end

    it 'allows valid affiliations' do
      names = ['st', 'cr', 'ns', 'os']

      names.each do |name|
        ip             = sample_ip_address
        ip.affiliation = name
        expect(ip.save).to    be_truthy
        expect(ip.destroy).to be_present
      end
    end
  end

  describe 'mac_address' do
    it 'is convert upcase characters to downcase' do
      ip             = sample_ip_address
      mac            = 'AA:BB:CC:DD:EE:FF'
      ip.mac_address = mac
      expect(ip.save).to        be_truthy
      expect(ip.mac_address).to eq(mac.downcase)
    end

    it 'is reject invalid length' do
      ip             = sample_ip_address
      ip.mac_address = 'AA:BB:CC'
      expect(ip.save).to be_falsy
    end

    it 'is reject only zero' do
      ip             = sample_ip_address
      ip.mac_address = '00:00:00:00:00:00'
      expect(ip.save).to be_falsy
    end

    it 'is convert hyphen to colon' do
      ip             = sample_ip_address
      mac            = '00-11-22-33-44-55'
      ip.mac_address = mac
      expect(ip.save).to        be_truthy
      expect(ip.mac_address).to eq(mac.gsub('-', ':'))
    end
  end

  describe '.delete_candidates_without_vm' do
    before(:each) do
      Fog.mock!
    end

    let(:graduated_uid) {user_information_by_role(:graduate).first}
    it "don't fetches ip of non-graduated users without VM" do
      user_informations.keys.reject{|k| k == graduated_uid}.each do |uid|
        user    = User.find_or_create_by(uid: uid)
        ip      = sample_ip_address
        ip.user = user

        expect(ip.save).to be_truthy
        expect(IpAddress.delete_candidates_without_vm).to be_empty
        expect(ip.destroy).to be_truthy
      end
    end

    it "don't fetches ip of all users with VM" do
      user_informations.keys.each do |uid|
        user    = User.find_or_create_by(uid: uid)
        ip      = sample_ip_address
        ip.user = user

        expect(ip.save).to be_truthy
        ip.create_virtual_machine(name: 'hoge', kvm_hostname: 'hogehoge')
        expect(IpAddress.delete_candidates_without_vm).to be_empty
        expect(ip.destroy).to be_truthy
      end
    end

    it 'fetches ip of graduated users without VM' do
      user          = User.find_or_create_by(uid: graduated_uid)
      ip            = sample_ip_address
      ip.user       = user

      expect(ip.save).to be_truthy
      candidates = IpAddress.delete_candidates_without_vm
      expect(candidates).to be_present
      expect(candidates.count).to eq(1)
    end
  end
end
