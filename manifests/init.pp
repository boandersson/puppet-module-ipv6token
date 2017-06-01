# Class: ipv6token
# ===========================
class ipv6token (
  $ensure             = 'present',
  $exclude_interfaces = [],
  $token_script_index = '10',
) inherits ::ipv6token::params {

  # validate parameters here


  # TODO: mkdir

  $file = "${::ipv6token::ifup_local_dir}/${::ipv6token::token_script_index}-${::ipv6token::token_script}"

  notify { "file: ${file}": }
  notice("file: ${file}")

  file { $file:
    ensure  => $::ipv6token::ensure,
    owner   => 'root',
    group   => 'root',
    mode    => '0744',
    content => template('ipv6token/set_ipv6_token.erb'),
  }

  # TODO: Notify network service. Need to test!
  # TODO: What about RHEL7?

}
