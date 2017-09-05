# == Class ipv6token::token_config
#
# Defined type for configuring ipv6 tokens per interface.
# This class supports SLES 12 and RHEL 7
#
# The title specifies the interface to configure
#
define ipv6token::token_config(
  $ensure,
  $script_dir,
  $token_script_index_prefix,
  $manage_wicked_postup = false,
) {

  validate_string($ensure)
  validate_string($token_script_index_prefix)
  validate_re($token_script_index_prefix, '^([0-9][0-9])$',
      'token_script_index_prefix must match [0-9][0-9]')
  validate_re($ensure, '^(present|absent)$',
      "ensure must be 'present' or 'absent', got <${ensure}>")
  validate_absolute_path($script_dir)

  $interface = $title

  $custom_token = getvar("::custom_ipv6_token_${interface}")

  if !defined($custom_token) or $custom_token != '' {
    $token_real = $custom_token
  }
  else {
    $token_real = getvar("::default_ipv6_token_${interface}")
  }

  if $token_real == '' {
    $ensure_real = 'absent'
  }
  else {
    $ensure_real = $ensure
  }

  $file = "${script_dir}/${token_script_index_prefix}set_ipv6_token-${interface}.sh"

  file { $file:
    ensure  => $ensure_real,
    owner   => 'root',
    group   => 'root',
    mode    => '0744',
    content => template('ipv6token/set_ipv6_token.erb'),
  }

  if $ensure_real == 'present' {
    # Need to deal with ensure absent as well. Only remove exact match!
    # Need to deal with manage_wicked_postup_script
    file_line { "wicked_postup_hook-${interface}":
      path  => "/etc/sysconfig/network/ifcfg-${interface}",
      line  => "POST_UP_SCRIPT=wicked:${token_script_index_prefix}set_ipv6_token-${interface}.sh"
    }

    exec { "set_ipv6_token-${interface}":
      command     => "${file} ${interface} up",
      refreshonly => true,
      subscribe   => File[$file],
    }
  }
}
