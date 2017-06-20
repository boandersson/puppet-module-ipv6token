# Class: ipv6token
# ===========================
class ipv6token (
  $ensure                    = 'present',
  $manage_ifup_local         = true,
  $manage_main_if_only       = true,
  $exclude_interfaces        = [],
  $token_script_index_prefix = '10',
) inherits ::ipv6token::params {

  validate_string($ensure)
  validate_array($exclude_interfaces)
  validate_string($token_script_index_prefix)
  validate_bool($manage_ifup_local)
  validate_bool($manage_main_if_only)

  validate_re($token_script_index_prefix, '^([0-9][0-9])$',
      'token_script_index_prefix must match [0-9][0-9]')
  validate_re($ensure, '^(present|absent)$',
      "ensure must be 'present' or 'absent', got <${ensure}>")

  if $manage_main_if_only {
    if !defined('$main_interface') or $::main_interface == '' {
      fail('Unable to find main interface (missing main_interface fact)')
    }
  }

  $file = "${::ipv6token::ifup_local_dir}/${::ipv6token::token_script_index_prefix}${::ipv6token::token_script}"

  file { $::ipv6token::ifup_local_dir:
    ensure => directory,
    owner  => root,
    group  => root,
    mode   => '0755',
  }

  if defined('$interfaces') and $::interfaces != '' {
    file { $file:
      ensure  => $::ipv6token::ensure,
      owner   => 'root',
      group   => 'root',
      mode    => '0744',
      content => template('ipv6token/set_ipv6_token.erb'),
    }

    exec { 'set_ipv6_token':
      command     => $file,
      refreshonly => true,
      subscribe   => File[$file],
    }

    if $manage_ifup_local {
      file { $::ipv6token::ifup_local_script:
        ensure => $::ipv6token::ensure,
        owner  => root,
        group  => 'root',
        mode   => '0755',
        source => 'puppet:///modules/ipv6token/ifup-local.rhel',
      }
    }
  }
}
