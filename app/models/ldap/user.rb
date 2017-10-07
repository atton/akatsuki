class LDAP::User < ActiveLdap::Base
  ObjectClasses = ['top', 'person', 'posixAccount', 'edyIEPerson',
                   'inetOrgPerson', 'shadowAccount', 'radiusprofile', 'sambaSamAccount']
  ldap_mapping dn_attribute: 'uid', prefix: '', classes: ObjectClasses

  belongs_to :groups, class_name: 'LDAP::Group', many: :memberUid

  attr_accessor :userPassword_confirmation

  validates_presence_of [:dn, :cn, :sn, :ou,
                         :uid, :uidNumber, :gidNumber, :gecos,
                         :homedirectory, :userPassword, :userPassword_confirmation, :loginShell]

  validates_confirmation_of :userPassword

  validate :validate_edy_id

  before_create do
    # check uid uniqueness. ActiveLDAP not has `validates_uniqueness_of'
     not [LDAP::User.exist?(self.uid), LDAP::User.search(filter: "uidNumber=#{self.uidNumber}").present?].any?
  end

  # ldapie "models.php" line 27
  def set_attributes_from_form_parameters params
    self.uid           = params[:uid]
    self.uidNumber     = params[:uidNumber]
    self.gidNumber     = IEConfig::LDAP::Group.id_from_group_name(params[:group])
    self.mail          = [params[:uid], IEConfig::LDAP::Domain].join('@')
    self.gecos         = params[:gecos]
    self.cn = self.sn  = params[:cn]
    self.ou            = params[:group]
    self.homeDirectory = ['', 'home' , self.ou, self.uid].join('/')
    self.userPassword  = ActiveLdap::UserPassword.md5(params[:password])
    self.userPassword_confirmation = ActiveLdap::UserPassword.md5(params[:password])
    self.dn            = ["uid=#{self.uid}", "ou=#{self.ou}", IEConfig::LDAP::BaseDN].join(',')
    set_samba_attributes(self.uidNumber , params[:password])
    set_default_attributes
    return self
  end

  def set_update_attributes_from_params params
    self.loginShell = params[:loginShell]
    edys            = params.select{|k,v| k.start_with?('ldapedyid_') && v.present?}.values.sort
    self.ldapedyid  = edys.blank? ? nil : edys
  end

  def set_passwords_from_form_parameters params
    return self unless self.bind(params[:current_password])
    return self if params[:userPassword].blank?

    self.userPassword              = ActiveLdap::UserPassword.md5(params[:userPassword])
    self.userPassword_confirmation = ActiveLdap::UserPassword.md5(params[:userPassword_confirmation])
    set_samba_attributes self.uidNumber, params[:userPassword] if self.userPassword_confirmation == self.userPassword
  rescue ActiveLdap::AuthenticationError
    raise '現在のパスワードの入力が間違っています'
  end

  def password_modifiable_by_akatsuki?
    ['teacher', 'adjunct', 'other'].include?(self.ou)
  end

  def notice_from_changes
    changed_values = changes.map do |k, v|
      next 'Edy IDの更新と端末への同期' if k == 'ldapedyid'
      next 'パスワードの変更'           if k == 'userPassword'
      next 'ログインシェルの変更'       if k == 'loginShell'
      nil
    end

    if changed_values.compact.present?
      changed_values.compact.join(',') + ' を行ないました'
    else
      '変更はありませんでした'
    end
  end

  # Group check methods
  def syskan?
    groups.map(&:cn).include?('syskan')
  end
  def iesudoer?
    groups.map(&:cn).include?('iesudoers')
  end
  def graduate?
    dn.rdns.any?{|el| el.value?('graduate')}
  end


  # Remove all registered EdyIDs with user from All EdyDevices
  def delete_edy
    msg = "SCNM=#{self.uid}"
    header = {'Cookie' => "WRPWD=#{IEConfig::LDAP::EdyPass}"}
    IEConfig::LDAP::EdyDevices.each do |device|
      begin
        http = Net::HTTP.new(device[1])
        http.open_timeout = IEConfig::LDAP::Timeout
        res = http.post('/card.cgi', msg, header)
        res.body.gsub(/(\s|\")|=|\[|\]/,"").split('cd')[1].split(';')[0].gsub(/\d{16}/,'').scan(/\d{5}/).each do |id|
          http.post('/card.cgi', "INDEX=#{id}&MODE=D", header)
        end
      rescue Timeout::Error
        next
      end
    end
  end

  # Register EdyID to All EdyDevices
  def register_edy
    Array.wrap(self.ldapedyid).each do |id|
      msg = "ID=#{id}&NAME=#{self.uid}&MODE=R"
      header = {'Cookie' => "WRPWD=#{IEConfig::LDAP::EdyPass}"}
      IEConfig::LDAP::EdyDevices.each do |device|
        begin
          http = Net::HTTP.new(device[1])
          http.open_timeout = IEConfig::LDAP::Timeout
          http.post('/card.cgi', msg, header)
        rescue Timeout::Error
          next
        end
      end
    end
  end

  private

  def set_samba_attributes uidNumber, password_string
    # authenticate parameter for Wireless LAN(RADIUS).
    self.sambaSid        = IEConfig::Samba.sambaid_from_uid uidNumber
    self.sambantpassword = Smbhash.ntlm_hash password_string
    return self
  end

  def set_default_attributes
    IEConfig::LDAP::DefaultAttributes.each do |k, v|
      self.send("#{k}=", v)
    end
    return self
  end

  def validate_edy_id
    Array.wrap(self.ldapedyid).each do |id|
      unless /\d{16}/ === id and id.length == 16
        self.errors.add(:ldap, 'edy の ID が不正です。 edy の ID は16桁の数値です。') and return false
      end
    end
  end

end
