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

  describe 'on RHEL6' do
    default_facts = {
      :osfamily                  => 'RedHat',
      :operatingsystemmajrelease => '6',
      :interfaces                => 'eth0,eth1,eth2,eth3',
      :main_interface            => 'eth0',
    }
    token_script_dir = '/etc/sysconfig/network-scripts/ifup-local.d'

    context 'with config for multiple interfaces' do
      let(:facts) do
        default_facts.merge(
          {
            :default_ipv6_token_eth0 => '::10',
            :default_ipv6_token_eth1 => '::11',
          }
        )
      end

      let(:params) { { :manage_main_if_only => false } }

      it do
        is_expected.to contain_file(token_script_dir).with(
          'ensure' => 'directory',
          'owner'  => 'root',
          'group'  => 'root',
          'mode'   => '0755',
        )
      end

      it { is_expected.to contain_file("#{token_script_dir}/10set_ipv6_token-eth0.sh").with({ 'ensure' => 'present' }) }
      it { is_expected.to contain_file("#{token_script_dir}/10set_ipv6_token-eth1.sh").with({ 'ensure' => 'present' }) }
      it { is_expected.to contain_file("#{token_script_dir}/10set_ipv6_token-eth2.sh").with({ 'ensure' => 'absent' }) }
      it { is_expected.to contain_file("#{token_script_dir}/10set_ipv6_token-eth3.sh").with({ 'ensure' => 'absent' }) }
    end

    context 'create ifup-local script' do
      let(:facts) { default_facts }

      it do
        is_expected.to contain_file('/sbin/ifup-local').with(
          {
            'ensure' => 'present',
            'owner'  => 'root',
            'group'  => 'root',
            'mode'   => '0755',
            'source' => 'puppet:///modules/ipv6token/ifup-local.rhel',
          }
        )
      end
    end

    context 'without managing ifup-local script' do
      let(:facts) { default_facts }
      let(:params) { { :manage_ifup_local => false, } }

      it { is_expected.not_to contain_file('/sbin/ifup-local') }
    end

    context 'with ensure absent' do
      let(:facts) do
        default_facts.merge(
          {
            :default_ipv6_token_eth0 => '::10',
            :default_ipv6_token_eth1 => '::11',
          }
        )
      end

      let(:params) do
        {
          :ensure              => 'absent',
          :manage_main_if_only => false,
        }
      end

      it { is_expected.to contain_file("#{token_script_dir}/10set_ipv6_token-eth0.sh").with({ 'ensure' => 'absent' }) }
      it { is_expected.to contain_file("#{token_script_dir}/10set_ipv6_token-eth1.sh").with({ 'ensure' => 'absent' }) }
      it { is_expected.to contain_file('/sbin/ifup-local').with({ 'ensure' => 'absent' }) }
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

      let(:params) { { :manage_main_if_only => true, } }

      it { is_expected.to contain_file("#{token_script_dir}/10set_ipv6_token-eth0.sh").with({ 'ensure' => 'present' }) }
      it { is_expected.not_to contain_file("#{token_script_dir}/10set_ipv6_token-eth1.sh").with({ 'ensure' => 'absent' }) }
    end

    context 'with manage main if only and no main if found' do
      let(:facts) do
        {
          :osfamily                  => 'RedHat',
          :operatingsystemmajrelease => '6',
          :interfaces                => 'eth0',
          :default_ipv6_token_eth0   => '::10',
        }
      end

      let(:params) { { :manage_main_if_only => true } }

      it 'should fail' do
        expect { should contain_class(subject) }.to raise_error(Puppet::Error, /missing main_interface fact./)
      end
    end

    context 'with all interfaces excluded' do
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
          :exclude_interfaces  => [ 'eth0', 'eth1', 'eth2', 'eth3' ],
          :manage_main_if_only => false,
        }
      end

      it { is_expected.not_to contain_file("#{token_script_dir}/10set_ipv6_token-eth0.sh") }
      it { is_expected.not_to contain_file("#{token_script_dir}/10set_ipv6_token-eth1.sh") }
      it { is_expected.not_to contain_file("#{token_script_dir}/10set_ipv6_token-eth2.sh") }
      it { is_expected.not_to contain_file("#{token_script_dir}/10set_ipv6_token-eth3.sh") }
    end

    context 'without any interfaces' do
      let(:facts) do
        {
          :osfamily                  => 'RedHat',
          :operatingsystemmajrelease => '6',
          :main_interface            => 'eth0',
        }
      end

      it { is_expected.not_to contain_file("#{token_script_dir}/10set_ipv6_token-eth0.sh") }
      it { is_expected.not_to contain_file("#{token_script_dir}/10set_ipv6_token-eth1.sh") }
      it { is_expected.not_to contain_file("#{token_script_dir}/10set_ipv6_token-eth2.sh") }
      it { is_expected.not_to contain_file("#{token_script_dir}/10set_ipv6_token-eth3.sh") }
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

      it { is_expected.not_to contain_file("#{token_script_dir}/10set_ipv6_token-eth0.sh") }
      it { is_expected.to contain_file("#{token_script_dir}/10set_ipv6_token-eth1.sh") }
      it { is_expected.not_to contain_file("#{token_script_dir}/10set_ipv6_token-eth2.sh") }
      it { is_expected.to contain_file("#{token_script_dir}/10set_ipv6_token-eth3.sh") }
    end

    context 'without config for other osreleases' do
      let(:facts) { default_facts.merge({ :default_ipv6_token_eth0   => '::10' }) }

      it { is_expected.not_to contain_file_line('wicked_postup_hook-eth0') }
      it { is_expected.not_to contain_file('/etc/wicked/scripts') }
      it { is_expected.not_to contain_file('/etc/NetworkManager/dispatcher.d') }
    end
  end

  describe 'on RHEL7' do
    default_facts = {
      :osfamily                  => 'RedHat',
      :operatingsystemmajrelease => '7',
      :interfaces                => 'eth0,eth1,eth2,eth3',
      :main_interface            => 'eth0',
    }
    token_script_dir = '/etc/NetworkManager/dispatcher.d'

    context 'with config for multiple interfaces' do
      let(:facts) do
        default_facts.merge(
          {
            :default_ipv6_token_eth0 => '::10',
            :default_ipv6_token_eth1 => '::11',
          }
        )
      end

      let(:params) { { :manage_main_if_only => false } }

      it do
        is_expected.to contain_file(token_script_dir).with(
          'ensure' => 'directory',
          'owner'  => 'root',
          'group'  => 'root',
          'mode'   => '0755',
        )
      end

      it { is_expected.to contain_file("#{token_script_dir}/10set_ipv6_token-eth0.sh").with({ 'ensure' => 'present' }) }
      it { is_expected.to contain_file("#{token_script_dir}/10set_ipv6_token-eth1.sh").with({ 'ensure' => 'present' }) }
      it { is_expected.to contain_file("#{token_script_dir}/10set_ipv6_token-eth2.sh").with({ 'ensure' => 'absent' }) }
      it { is_expected.to contain_file("#{token_script_dir}/10set_ipv6_token-eth3.sh").with({ 'ensure' => 'absent' }) }
    end

    context 'without config for other osreleases' do
      let(:facts) { default_facts }

      it { is_expected.not_to contain_file_line('wicked_postup_hook-eth0') }
      it { is_expected.not_to contain_file('/sbin/ifup-local') }
      it { is_expected.not_to contain_file('/etc/wicked/scripts') }
      it { is_expected.not_to contain_file('/etc/sysconfig/network-scripts/ifup-local.d') }
    end
  end

  describe 'on SLES 12' do
    default_facts = {
      :osfamily               => 'Suse',
      :operatingsystemrelease => '12',
      :interfaces             => 'eth0,eth1,eth2,eth3',
      :main_interface         => 'eth0',
    }

    context 'with config for multiple interfaces' do
      let(:facts) do
        default_facts.merge(
          {
            :default_ipv6_token_eth0 => '::10',
            :default_ipv6_token_eth1 => '::11',
          }
        )
      end

      let(:params) { { :manage_main_if_only => false } }

      it do
        is_expected.to contain_file('/etc/wicked/scripts').with(
          'ensure' => 'directory',
          'owner'  => 'root',
          'group'  => 'root',
          'mode'   => '0755',
        )
      end

      it { is_expected.to contain_file("/etc/wicked/scripts/set_ipv6_token-eth0.sh").with({ 'ensure' => 'present' }) }
      it { is_expected.to contain_file("/etc/wicked/scripts/set_ipv6_token-eth1.sh").with({ 'ensure' => 'present' }) }
      it { is_expected.to contain_file("/etc/wicked/scripts/set_ipv6_token-eth2.sh").with({ 'ensure' => 'absent' }) }
      it { is_expected.to contain_file("/etc/wicked/scripts/set_ipv6_token-eth3.sh").with({ 'ensure' => 'absent' }) }
    end

    context 'without config for other osreleases' do
      let(:facts) { default_facts }

      it { is_expected.not_to contain_file('/sbin/ifup-local') }
      it { is_expected.not_to contain_file('/etc/sysconfig/network-scripts/ifup-local.d') }
      it { is_expected.not_to contain_file('/etc/NetworkManager/dispatcher.d') }
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
