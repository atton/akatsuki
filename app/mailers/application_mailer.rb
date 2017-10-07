class ApplicationMailer < ActionMailer::Base
  default from: 'sys-admin@ie.u-ryukyu.ac.jp', reply_to: 'sys-admin@ie.u-ryukyu.ac.jp'
  layout 'mailer'
end
