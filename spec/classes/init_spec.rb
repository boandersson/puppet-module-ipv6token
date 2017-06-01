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

  context 'set ipv6 token' do
    default_facts = {
      :osfamily                  => 'RedHat',
      :operatingsystemmajrelease => '6',
      :interfaces                => 'eth0,eth1,eth2,eth3',
    }
    token_script_dir = '/etc/sysconfig/network-scripts/ifup-local.d'
    default_token_script = "#{token_script_dir}/10-set_ipv6_tokens.sh"

    describe 'setup token script' do
      let(:facts) do
        default_facts.merge(
          {
            :default_ipv6_token_eth0   => '::0',
          }
        )

        it { is_expected.to contain_file(token_script_dir).with(
            'ensure' => 'directory',
            'owner'  => 'root',
            'group'  => 'root',
            'mode'   => '0755',
          )}
        it { is_expected.to contain_file(default_token_script).with(
            'ensure' => 'present',
            'owner'  => 'root',
            'group'  => 'root',
            'mode'   => '0755',
          )}
      end
    end

    describe 'with ensure absent' do
      let(:facts) { default_facts }
      let(:params) { { :ensure => 'absent' } }

      it { is_expected.to contain_file(default_token_script).with('ensure' => 'absent', ) }
    end

    describe 'with custom script order' do
      let(:facts) { default_facts }
      let(:params) { { :token_script_index => '42' } }

      it { is_expected.to contain_file("#{token_script_dir}/42-set_ipv6_tokens.sh") }
    end

    describe 'mixing default- and custom token facts' do
      let(:facts) do
        default_facts.merge(
          {
            :default_ipv6_token_eth0   => '::0',
            :default_ipv6_token_eth1   => '::1',
            :custom_ipv6_token_eth1    => '::2',
          }
        )
      end

      fixture = File.read(fixtures("ipv6_tokens_for_all_interfaces"))

      it { is_expected.to contain_file(default_token_script).with_content(fixture) }
    end

    describe 'with excluded interfaces' do
      let(:facts) do
        default_facts.merge(
          {
            :default_ipv6_token_eth0   => '::0',
            :default_ipv6_token_eth1   => '::1',
            :default_ipv6_token_eth2   => '::2',
          }
        )
      end

      let(:params) { { :exclude_interfaces => [ 'eth0', 'eth2' ] } }

      fixture = File.read(fixtures("ipv6_tokens_with_excluded_interfaces"))

      it { is_expected.to contain_file(default_token_script).with_content(fixture) }
    end
  end
end
