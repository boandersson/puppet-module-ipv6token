require 'spec_helper'

describe 'ipv6token' do
  context 'supported operating systems' do
    on_supported_os.each do |os, facts|
      context "on #{os}" do
        let(:facts) do
          facts
        end

        context "ipv6token class without any parameters" do
          it { is_expected.to compile.with_all_deps }

          it { is_expected.to contain_class('ipv6token::params') }
          it { is_expected.to contain_class('ipv6token::install').that_comes_before('ipv6token::config') }
          it { is_expected.to contain_class('ipv6token::config') }
          it { is_expected.to contain_class('ipv6token::service').that_subscribes_to('ipv6token::config') }

          it { is_expected.to contain_service('ipv6token') }
          it { is_expected.to contain_package('ipv6token').with_ensure('present') }
        end
      end
    end
  end

  context 'unsupported operating system' do
    describe 'ipv6token class without any parameters on Solaris/Nexenta' do
      let(:facts) do
        {
          :osfamily        => 'Solaris',
          :operatingsystem => 'Nexenta',
        }
      end

      it { expect { is_expected.to contain_package('ipv6token') }.to raise_error(Puppet::Error, /Nexenta not supported/) }
    end
  end
end
