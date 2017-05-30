# == Class ipv6token::install
#
# This class is called from ipv6token for install.
#
class ipv6token::install {

  package { $::ipv6token::package_name:
    ensure => present,
  }
}
