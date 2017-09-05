# == Class ipv6token::params
#
# This class is meant to be called from ipv6token.
#
class ipv6token::params {
  case $::osfamily {
    'RedHat': {
      case $::operatingsystemmajrelease {
        '6': {
          $ifup_local_dir = '/etc/sysconfig/network-scripts/ifup-local.d'
          $ifup_local_script = '/sbin/ifup-local'
        }
        '7': {
          $ifup_local_dir = '/etc/NetworkManager/dispatcher.d'
        }
        default: {
          fail("RedHat ${::operatingsystemmajrelease} not supported")
        }
      }
    }
    'Suse': {
      # Suse doesn't support $::operatingsystemmajrelease.
      case $::operatingsystemrelease {
        '/^12\.': {
          # $token_script = 'set_ipv6_tokens.sh'
        }
        default: {
          fail("SuSE ${::operatingsystemrelease} not supported")
        }
      }
    }
    default: {
      fail("Operating system ${::operatingsystem} not supported")
    }
  }
}
