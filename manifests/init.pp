# Class: ipv6token
# ===========================
class ipv6token (
  $ensure                    = 'present',
  $manage_ifup_local         = true,
  $manage_main_if_only       = true,
  $exclude_interfaces        = [],
  $token_script_index_prefix = '10',
) inherits ::ipv6token::params {

  validate_array($exclude_interfaces)
  validate_bool($manage_ifup_local)
  validate_bool($manage_main_if_only)

  if $manage_main_if_only {
    if !defined('$main_interface') or $::main_interface == '' {
      fail('Unable to find main interface (missing main_interface fact)')
    }
  }

  if defined('$interfaces') and $::interfaces != '' {
    case $::osfamily {
      'RedHat': {
        if ($manage_main_if_only) {
          $interfaces_real = [ $::main_interface ]
        }
        else {
          #$interfaces_real = split($::interfaces, ',') - $exclude_interfaces
          $interfaces_real = split($::interfaces, ',')
        }

        file { $::ipv6token::ifup_local_dir:
          ensure => directory,
          owner  => root,
          group  => root,
          mode   => '0755',
        }

        token_config { $interfaces_real:
          ensure                    => $::ipv6token::ensure,
          script_dir                => $::ipv6token::ifup_local_dir,
          token_script_index_prefix => $::ipv6token::token_script_index_prefix,
          require                   => File[$::ipv6token::ifup_local_dir]
        }

        if $::operatingsystemmajrelease == '6' and $manage_ifup_local {
          file { $::ipv6token::ifup_local_script:
            ensure => $::ipv6token::ensure,
            owner  => root,
            group  => 'root',
            mode   => '0755',
            source => 'puppet:///modules/ipv6token/ifup-local.rhel',
          }
        }
      }
      'Suse': {
        # Install file - the file can only support a single interface.
        #   Use a single script containing all the tokens
        #   but rely on the interface arg passed from wicked, i.e. only set token
        #   for the interface being configured from wicked
        # Update ifcfg-<interface> - needs defined type to be able to Update
        # files for all interfaces.
        fail('not impl')
      }
      default: {
        fail("Operating system ${::operatingsystem} not supported")
      }
    }
  }
}
