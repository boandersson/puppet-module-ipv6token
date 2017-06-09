# Class: ipv6token
# ===========================
class ipv6token (
  $ensure             = 'present',
  $exclude_interfaces = [],
  $token_script_index = '10',
) inherits ::ipv6token::params {

  validate_string($ensure)
  validate_array($exclude_interfaces)
  validate_string($token_script_index)

  validate_re($token_script_index, '^([0-9][0-9])$',
      'token_script_index must match [0-9][0-9]')
  validate_re($ensure, '^(present|absent)$',
      "ensure must be 'present' or 'absent', got <${ensure}>")

  $file = "${::ipv6token::ifup_local_dir}/${::ipv6token::token_script_index}-${::ipv6token::token_script}"

  file { $::ipv6token::ifup_local_dir:
    ensure => directory,
    owner  => root,
    group  => root,
    mode   => '0755',
  }

  if $::interfaces == undef or $::interfaces == '' {
    $ensure_real = 'absent'
  }
  else {
    $ensure_real = $::ipv6token::ensure
  }

  if $::interfaces != undef and $::interfaces != '' {
    file { $file:
      ensure  => $::ipv6token::ensure,
      owner   => 'root',
      group   => 'root',
      mode    => '0744',
      content => template('ipv6token/set_ipv6_token.erb'),
    }
  }

  # TODO: Notify network service. Need to test!
  # TODO: What about RHEL7?

}