# Class: ipv6token
# ===========================
#
# Full description of class ipv6token here.
#
# Parameters
# ----------
#
# * `sample parameter`
#   Explanation of what this parameter affects and what it defaults to.
#   e.g. "Specify one or more upstream ntp servers as an array."
#
class ipv6token (
  ensure             = 'present',
  exclude_interfaces = undef,
  token_script_index = '00',
) inherits ::ipv6token::params {

  # validate parameters here

  #class { '::ipv6token::install': } ->
  #class { '::ipv6token::config': } ~>
  #class { '::ipv6token::service': } ->
  #Class['::ipv6token']

  ifup-local-dir = '/etc/sysconfig/network-scripts/ifup-local.d'
  token_script = 'set_ipv6_token.sh'

  file { "${::ipv6token::ifup_local_dir}/${::ipv6token::token_script_index}-${::ipv6token::token_script}":
    ensure  => $::ipv6token::ensure,
    owner   => 'root',
    group   => 'root',
    mode    => '0744',
    content => template('ipv6token/set_ipv6_token.erb'),
  }

}
