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
          $token_script = 'set_ipv6_tokens.sh'
        }
        default: {
          fail("RedHat ${::operatingsystemmajrelease} not supported")
        }
      }
    }
    default: {
      fail("${::operatingsystem} not supported")
    }
  }
}
