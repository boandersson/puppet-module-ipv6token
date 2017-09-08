# Class: ipv6token
# ===========================
class ipv6token (
  $ensure                      = 'present',
  $manage_ifup_local           = true,
  #$manage_wicked_postup_script = false,
  $manage_main_if_only         = true,
  $exclude_interfaces          = [],
  $token_script_index_prefix   = '10',
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
    if ($manage_main_if_only) {
      $interfaces_real = [ $::main_interface ]
    }
    else {
      # Use delete() instead of '-' as the latter requires future parser
      $interfaces_real = delete(split($::interfaces, ','), $exclude_interfaces)
    }

    file { $::ipv6token::ifup_local_dir:
      ensure => directory,
      owner  => root,
      group  => root,
      mode   => '0755',
    }

    case $::osfamily {
      'RedHat': {
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
        token_config { $interfaces_real:
          ensure                    => $::ipv6token::ensure,
          script_dir                => $::ipv6token::ifup_local_dir,
          token_script_index_prefix => $::ipv6token::token_script_index_prefix,
          require                   => File[$::ipv6token::ifup_local_dir]
        }
      }
      default: {
        fail("Operating system ${::operatingsystem} not supported")
      }
    }
  }
}
