# == Class ipv6token::service
#
# This class is meant to be called from ipv6token.
# It ensure the service is running.
#
class ipv6token::service {

  service { $::ipv6token::service_name:
    ensure     => running,
    enable     => true,
    hasstatus  => true,
    hasrestart => true,
  }
}
