require "rails_helper"

RSpec.describe IpAddressMailer, type: :mailer do
  describe 'notify_to_user' do
    it 'has validation to actions' do
      expect{IpAddressMailer.notify_to_user(nil, nil, :hoge, nil).deliver_now}.to raise_error(RuntimeError)
    end
  end
end
