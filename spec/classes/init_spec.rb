require 'spec_helper'

describe 'ipv6token' do
  context 'supported operating systems' do
    on_supported_os.each do |os, facts|
      context "on #{os}" do
        let(:facts) do
          facts.merge({ :main_interface => 'eth0' })
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

  describe 'set ipv6 token' do
    default_facts = {
      :osfamily                  => 'RedHat',
      :operatingsystemmajrelease => '6',
      :interfaces                => 'eth0,eth1,eth2,eth3',
      :main_interface            => 'eth0',
    }
    token_script_dir = '/etc/sysconfig/network-scripts/ifup-local.d'
    default_token_script = "#{token_script_dir}/10set_ipv6_tokens.sh"

    context 'token script' do
      let(:facts) do
        default_facts.merge({ :default_ipv6_token_eth0   => '::10', })
      end

      it do
        is_expected.to contain_file(token_script_dir).with(
          'ensure' => 'directory',
          'owner'  => 'root',
          'group'  => 'root',
          'mode'   => '0755',
        )
      end
      it do
        is_expected.to contain_file(default_token_script).with(
          'ensure' => 'present',
          'owner'  => 'root',
          'group'  => 'root',
          'mode'   => '0744',
        )
      end
      it do
        is_expected.to contain_exec('set_ipv6_token').with(
          'command'     => "#{token_script_dir}/10set_ipv6_tokens.sh",
          'refreshonly' => true,
          'subscribe'   => "File[#{token_script_dir}/10set_ipv6_tokens.sh]",
        )
      end
      it do
        is_expected.to contain_file('/sbin/ifup-local').with(
          'ensure' => 'present',
          'owner'  => 'root',
          'group'  => 'root',
          'mode'   => '0755',
          'source' => 'puppet:///modules/ipv6token/ifup-local.rhel',
        )
      end
    end

    context 'create ifup-local script' do
      let(:facts) { default_facts }

      it do
        is_expected.to contain_file('/sbin/ifup-local').with(
          'ensure' => 'present',
          'owner'  => 'root',
          'group'  => 'root',
          'mode'   => '0755',
          'source' => 'puppet:///modules/ipv6token/ifup-local.rhel',
        )
      end
    end

    context 'without managing ifup-local script' do
      let(:facts) { default_facts }
      let(:params) { { :manage_ifup_local => false, } }

      it { is_expected.not_to contain_file('/sbin/ifup-local') }
    end

    context 'with ensure absent' do
      let(:facts) { default_facts }
      let(:params) { { :ensure => 'absent' } }

      it { is_expected.to contain_file(default_token_script).with('ensure' => 'absent', ) }
      it { is_expected.to contain_file('/sbin/ifup-local').with('ensure' => 'absent', ) }
    end

    context 'with custom script order' do
      let(:facts) { default_facts }
      let(:params) { { :token_script_index_prefix => '42' } }

      it { is_expected.to contain_file("#{token_script_dir}/42set_ipv6_tokens.sh").with('ensure' => 'present') }
      it do
        is_expected.to contain_exec('set_ipv6_token').with(
          'command'     => "#{token_script_dir}/42set_ipv6_tokens.sh",
          'refreshonly' => true,
          'subscribe'   => "File[#{token_script_dir}/42set_ipv6_tokens.sh]",
        )
      end
    end

    context 'mixing default- and custom token facts' do
      let(:params) { { :manage_main_if_only => false } }
      let(:facts) do
        default_facts.merge(
          {
            :default_ipv6_token_eth0   => '::10',
            :default_ipv6_token_eth1   => '::11',
            :custom_ipv6_token_eth1    => '::12',
          }
        )
      end

      fixture = File.read(fixtures("ipv6_tokens_for_all_interfaces"))

      it { is_expected.to contain_file(default_token_script).with_content(fixture) }
    end

    context 'with manage main if only' do
      let(:facts) do
        default_facts.merge(
          {
            :default_ipv6_token_eth0   => '::10',
            :default_ipv6_token_eth1   => '::11',
          }
        )
      end

      fixture = File.read(fixtures("ipv6_tokens_with_main_interface_only"))

      it { is_expected.to contain_file(default_token_script).with_content(fixture) }
    end

    context 'with main if excluded' do
      let(:facts) do
        default_facts.merge(
          {
            :default_ipv6_token_eth0   => '::10',
            :default_ipv6_token_eth1   => '::11',
          }
        )
      end

      let(:params) { { :exclude_interfaces  => [ 'eth0', 'eth2' ] } }

      it { is_expected.to contain_file(default_token_script).with_content(/didn't find any interfaces to set ipv6 tokens for./) }
    end

    context 'with main interface not found' do
      let(:facts) do
        {
          :osfamily                  => 'RedHat',
          :operatingsystemmajrelease => '6',
          :interfaces                => 'eth0',
        }
      end

      it 'should fail' do
        expect { should contain_class(subject) }.to raise_error(Puppet::Error, /missing main_interface fact./)
      end
    end

    context 'without any interfaces' do
      let(:facts) do
        {
          :osfamily                  => 'RedHat',
          :operatingsystemmajrelease => '6',
          :main_interface            => 'eth0',
        }
      end

      it { is_expected.not_to contain_file(default_token_script) }
      it { is_expected.not_to contain_file('/sbin/ifup-local') }
    end

    context 'with excluded interfaces' do
      let(:facts) do
        default_facts.merge(
          {
            :default_ipv6_token_eth0   => '::10',
            :default_ipv6_token_eth1   => '::11',
            :default_ipv6_token_eth2   => '::12',
            :default_ipv6_token_eth3   => '::13',
          }
        )
      end

      let(:params) do
        {
          :manage_main_if_only => false,
          :exclude_interfaces  => [ 'eth0', 'eth2' ],
        }
      end

      fixture = File.read(fixtures("ipv6_tokens_with_excluded_interfaces"))

      it { is_expected.to contain_file(default_token_script).with_content(fixture) }
    end
  end

  describe 'validations' do
    let(:validation_params) { { } }

    let(:facts) do
      {
        :osfamily                  => 'RedHat',
        :operatingsystemmajrelease => '6',
        :interfaces                => 'eth0',
        :main_interface            => 'eth0',
      }
    end

    validations = {
      'boolean' => {
        :name    => %w(manage_ifup_local manage_main_if_only),
        :valid   => [ true, false ],
        :invalid => [{ 'ha' => 'sh' }, 42, 'true', [ 'array' ] ],
        :message => 'not a boolean',
      },
      'ensure' => {
        :name    => %w(ensure),
        :valid   => [ 'present', 'absent' ],
        :invalid => [{ 'ha' => 'sh' }, 42, true, 'string', [ 'array' ] ],
        :message => 'is not a string|must be .present. or .absent.'
      },
      'token_script_index_prefix' => {
        :name    => %w(token_script_index_prefix),
        :valid   => [ '00', '10', '99' ],
        :invalid => [{ 'ha' => 'sh' }, 42.2, 433, true, 'string', [ 'array' ] ],
        :message => 'token_script_index_prefix must match|is not a string'
      },
      'exclude_interfaces' => {
        :name    => %w(exclude_interfaces),
        :valid   => [ [ 'eth0' ], [] ],
        :invalid => [{ 'ha' => 'sh' }, 42, true, 'string' ],
        :message => 'is not an Array'
      }
    }

    validations.sort.each do |type, validation|
      validation[:name].each do |param_name|
        validation[:valid].each do |valid|
          context "with #{param_name} (#{type}) set to valid #{valid} (as #{valid.class})" do
            let(:params) { validation_params.merge({ :"#{param_name}" => valid, }) }
            it { should compile }
          end
        end

        validation[:invalid].each do |invalid|
          context "with #{param_name} (#{type}) set to invalid #{invalid} (as #{invalid.class})" do
            let(:params) { validation_params.merge({ :"#{param_name}" => invalid, }) }
            it 'should fail' do
              expect { should contain_class(subject) }.to raise_error(Puppet::Error, /#{validation[:message]}/)
            end
          end
        end
      end # var[:name].each
    end # validations.sort.each
  end
end
