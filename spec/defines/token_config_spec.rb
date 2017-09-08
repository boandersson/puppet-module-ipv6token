require 'spec_helper'

describe 'ipv6token::token_config', :type => :define do
  describe 'configure' do
    default_facts = {
      :default_ipv6_token_eth0 => '::10',
      :default_ipv6_token_eth1 => '::11',
      :default_ipv6_token_eth2 => '::12',
      :custom_ipv6_token_eth2  => '::13',
      :osfamily                => 'RedHat',
    }

    default_params = {
      :ensure                    => 'present',
      :script_dir                => '/tmp',
      :token_script_index_prefix => '10',
    }

    context 'token script' do
      let(:title) { 'eth0' }
      let(:facts) { default_facts }
      let(:params) { default_params }

      it do
        is_expected.to contain_file('/tmp/10set_ipv6_token-eth0.sh').with(
          'ensure' => 'present',
          'owner'  => 'root',
          'group'  => 'root',
          'mode'   => '0744',
        )
      end

      fixture = File.read(fixtures("ipv6_token_for_eth0"))
      it { is_expected.to contain_file('/tmp/10set_ipv6_token-eth0.sh').with_content(fixture) }

      it do
        is_expected.to contain_exec('set_ipv6_token-eth0').with(
          'command'     => "/tmp/10set_ipv6_token-eth0.sh eth0 up",
          'refreshonly' => true,
          'subscribe'   => "File[/tmp/10set_ipv6_token-eth0.sh]",
        )
      end

      it { is_expected.not_to contain_file_line('wicked_postup_hook') }
    end

    context 'interface without token' do
      let(:title) { 'eth3' }
      let(:facts) { default_facts }
      let(:params) { default_params }

      it { is_expected.to contain_file('/tmp/10set_ipv6_token-eth3.sh').with({ 'ensure' => 'absent' }) }
    end

    context 'with ensure absent' do
      let(:title) { 'eth0' }
      let(:facts) { default_facts }
      let(:params) { default_params.merge({ :ensure => 'absent' }) }

      it { is_expected.to contain_file('/tmp/10set_ipv6_token-eth0.sh').with({ 'ensure' => 'absent' }) }
      it { is_expected.not_to contain_exec('set_ipv6_token-eth0') }
    end

    context 'with ensure absent removes files even if token is missing' do
      let(:title) { 'eth0' }
      let(:facts) { { :osfamily => 'RedHat' } }
      let(:params) { default_params.merge({ :ensure => 'absent' }) }

      it { is_expected.to contain_file('/tmp/10set_ipv6_token-eth0.sh').with({ 'ensure' => 'absent' }) }
    end

    context 'with custom script order' do
      let(:title) { 'eth0' }
      let(:facts) { default_facts }
      let(:params) { default_params.merge({ :token_script_index_prefix => '42' }) }

      it { is_expected.to contain_file('/tmp/42set_ipv6_token-eth0.sh').with({ 'ensure' => 'present' }) }
      it do
        is_expected.to contain_exec('set_ipv6_token-eth0').with(
          'command'     => "/tmp/42set_ipv6_token-eth0.sh eth0 up",
          'refreshonly' => true,
          'subscribe'   => "File[/tmp/42set_ipv6_token-eth0.sh]",
        )
      end
    end

    context 'mixing default- and custom token facts' do
      let(:title) { 'eth2' }
      let(:facts) { default_facts }
      let(:params) { default_params }

      fixture = File.read(fixtures('ipv6_token_for_eth2'))

      it { is_expected.to contain_file('/tmp/10set_ipv6_token-eth2.sh').with_content(fixture) }
    end
  end

  describe 'configure sles12' do
    default_facts = {
      :default_ipv6_token_eth0 => '::10',
      :osfamily                => 'Suse',
      :operatingsystemrelease  => '12',
    }

    default_params = {
      :ensure                      => 'present',
      :script_dir                  => '/tmp',
      :token_script_index_prefix   => '10',
      :manage_wicked_postup_script => 'true',
    }

    context 'creates wicked post-up hook' do
      let(:title) { 'eth0' }
      let(:facts) { default_facts }
      let(:params) { default_params.merge({ :manage_wicked_postup_script => true }) }

      it do
        is_expected.to contain_file_line('wicked_postup_hook-eth0').only_with({
          'ensure'            => 'present',
          'path'              => '/etc/sysconfig/network/ifcfg-eth0',
          'line'              => 'POST_UP_SCRIPT="wicked:set_ipv6_token-eth0.sh"',
          'match'             => '^POST_UP_SCRIPT=',
          'match_for_absence' => false,
        })
      end
    end

    context 'doesnt create wicked post-up hook when ensure absent' do
      let(:title) { 'eth0' }
      let(:facts) { default_facts }
      let(:params) do
        default_params.merge(
          {
            :ensure                      => 'absent',
            :manage_wicked_postup_script => true
          }
        )
      end

      it do
        is_expected.to contain_file_line('wicked_postup_hook-eth0').only_with({
          'ensure'            => 'absent',
          'path'              => '/etc/sysconfig/network/ifcfg-eth0',
          'line'              => 'POST_UP_SCRIPT="wicked:set_ipv6_token-eth0.sh"',
          'match'             => '^POST_UP_SCRIPT=',
          'match_for_absence' => false,
        })
      end
    end

    context 'doesnt create wicked post-up hook without manage_wicked_postup_script param' do
      let(:title) { 'eth0' }
      let(:facts) { default_facts }
      let(:params) { default_params.merge({ :manage_wicked_postup_script => false }) }

      it { is_expected.not_to contain_file_line('wicked_postup_hook-eth0') }
    end

    [ '6', '7' ].each do |osrelease|
      context 'doesnt create wicked post-up hook on RedHat #{osrelease}' do
        let(:title) { 'eth0' }
        let(:params) { default_params.merge({ :manage_wicked_postup_script => true }) }
        let(:facts) do
          default_facts.merge(
            :osfamily                  => 'RedHat',
            :operatingsystemmajrelease => osrelease,
          )
        end

        it { is_expected.not_to contain_file_line('wicked_postup_hook-eth0') }
      end
    end
  end

  describe 'validations' do
    let(:title) { 'eth0' }
    let(:validation_params) do
      {
        :ensure                    => 'present',
        :script_dir                => '/tmp',
        :token_script_index_prefix => '10',
      }
    end

    let(:facts) do
      {
        :osfamily                  => 'RedHat',
        :operatingsystemmajrelease => '6',
        :interfaces                => 'eth0',
        :main_interface            => 'eth0',
      }
    end

    validations = {
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
      'script_dir' => {
        :name    => %w(script_dir),
        :valid   => [ '/tmp' ],
        :invalid => [{ 'ha' => 'sh' }, 42, true, 'string' ],
        :message => 'is not an absolute path'
      },
      'manage_wicked_postup_script' => {
        :name    => %w(manage_wicked_postup_script),
        :valid   => [ true, false ],
        :invalid => [{ 'ha' => 'sh' }, 42, [ 'array' ], 'string' ],
        :message => 'is not a boolean'
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
