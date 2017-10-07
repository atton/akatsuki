class IpAddressMailer < ApplicationMailer
  NotificationMessagesForAction = {
    create:  '作成',
    update:  '編集',
    destroy: '削除',
  }

  def notify_to_user user, remote_ip, action, ip
    raise "#{action} is not supported" unless NotificationMessagesForAction.key?(action)
    @action_message   = NotificationMessagesForAction[action]
    @ldap_user        = user.ldap_user
    @ip               = ip
    @show_static_info = [:create, :update].any?{|a| a == action}
    @remote_ip        = remote_ip

    logger.info("#{@ldap_user.uid}(#{@remote_ip}), #{action.to_s}, #{ip.mac_address}, #{ip.assigned_address}")
    if @ldap_user.mail.present?
      mail(to: @ldap_user.mail, subject: "IP#{@action_message}通知 (#{ip.fqdn})")
    end
  end

  def notify_migration_ip_without_vm uid, tbl_data, before_ip_addresses
    @tbl_data            = tbl_data
    @before_ip_addresses = before_ip_addresses
    mail(to:       LDAP::User.find(uid).mail,
         subject:  'システム移行に伴なうIP変更のお知らせ')
  end

  def notify_migration_vm uid, vm, mac, ipv4, ipv6
    @vm   = vm
    @mac  = mac
    @ipv4 = ipv4
    @ipv6 = ipv6
    mail(to:      LDAP::User.find(uid).mail,
         subject: 'システム移行に伴なうVMのIP変更のお知らせ')
  end
end
