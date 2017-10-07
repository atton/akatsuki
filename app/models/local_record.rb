class LocalRecord < ActiveRecord::Base
  SourceHost    = 'urasoe.ie.u-ryukyu.ac.jp.'
  ContactEmail  = 'hostmaster.ie.u-ryukyu.ac.jp.'
  RefreshSecond = 8.hours.to_i
  RetrySecond   = 2.hours.to_i
  ExpireSecond  = 4.weeks.to_i
  MinTTLSecond  = 24.hours.to_i

  belongs_to :ip_address

  validates_presence_of  :rdtype, :ttl, :name
  validates_inclusion_of :rdtype, in: ['NS', 'SOA', 'PTR', 'CNAME', 'A', 'AAAA', 'MX', 'TXT']

  def soa_from_serial serial
    [SourceHost, ContactEmail, serial, RefreshSecond, RetrySecond,  ExpireSecond,  MinTTLSecond].map(&:to_s).join(' ')
  end

  def soa_record
    case self.rdtype
    when 'A'
      LocalRecord.where(name: ip_address.affiliation_detail.fqdn , rdtype: 'SOA').first
    when 'AAAA'
      LocalRecord.where(name: ip_address.affiliation_detail.fqdn , rdtype: 'SOA').first
    when 'PTR'
      if self.name.include?('addr')
        LocalRecord.where(name: (ip_address.rev4).split('.').drop(1).join('.'), rdtype: 'SOA').first
      elsif self.name.include?('ip6')
        LocalRecord.where(name: ip_address.affiliation_detail.rev6 , rdtype: 'SOA').first
      end
    else
      return nil
    end
  rescue ActiveRecord::RecordNotFound
    return nil
  end

  def update_serial
    return self.soa_record.try(:update_serial) unless self.rdtype == 'SOA'

    today_serial   = Time.now.strftime('%Y%m%d00')
    current_serial = self.rdata.split(' ').try(:[], 2)

    if current_serial.to_i >= today_serial.to_i
      self.rdata = soa_from_serial(current_serial.succ)
    else
      self.rdata = soa_from_serial(today_serial)
    end
    return self.save
  end
end
