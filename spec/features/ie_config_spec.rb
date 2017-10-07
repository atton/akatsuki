require 'rails_helper'

describe IEConfig do
  describe 'IEConfig::KVM' do
    describe '::TemplateVolumeNameRegex' do
      it 'match to template name' do
        expect('template-CentOS7.qcow2').to  match(IEConfig::KVM::TemplateVolumeNameRegex)
        expect('template-Fedora22.qcow2').to match(IEConfig::KVM::TemplateVolumeNameRegex)

      end

      it 'reject to not templates' do
        expect('templateCentOS7.qcow2').to_not match(IEConfig::KVM::TemplateVolumeNameRegex)
        expect('hoge.sh').to_not               match(IEConfig::KVM::TemplateVolumeNameRegex)
        expect('template-CentOS6.img').to_not  match(IEConfig::KVM::TemplateVolumeNameRegex)
      end
    end

    describe '.not_busy_hostname' do
      before(:each) do
        Fog.mock!
        Fog::Mock.reset
      end

      it 'return connection with load balancing' do
        very_busy_host  = double('very_busy_host')
        busy_host       = double('busy_host')
        not_busy_host   = double('not_busy_host')

        hosts = [very_busy_host, not_busy_host, busy_host]
        hosts.zip([100, 20, 50]).each do |host, num|
          allow(host).to receive_message_chain(:connection, :servers, :size).and_return(num)
        end
        allow(not_busy_host).to receive(:name).and_return('hogee')
        stub_const('IEConfig::KVM::HostInformations', hosts.shuffle)

        expect(IEConfig::KVM.not_busy_hostname).to eq('hogee')
      end
    end

    describe '.connection' do
      before(:each) do
        Fog.mock!
        Fog::Mock.reset
      end

      it 'raise with hostname which not included in IEConfig::KVM::HostInformations' do
        stub_const('IEConifg::KVM::HostInformations',
                   [IEConfig::KVM::HostInformation.new('hoge', ''),
                    IEConfig::KVM::HostInformation.new('fuga', '')])
        expect{IEConfig::KVM.connection('poyo')}.to raise_error(RuntimeError)
      end

      it 'return not busy connection without argument' do
        stub_const('IEConifg::KVM::Hosts', ['poyo'])
        allow(IEConfig::KVM).to receive(:not_busy_hostname).and_return('poyo')
        allow(IEConfig::KVM).to receive(:connection).and_call_original
        allow(IEConfig::KVM).to receive(:connection).with('poyo').and_return(100)
        IEConfig::KVM.connection
      end
    end

  end
end

