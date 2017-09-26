# == Class ipv6token::token_config
#
# Defined type for configuring ipv6 tokens per interface.
#
# The title specifies the interface to configure
#
define ipv6token::token_config(
  $ensure,
  $script_dir,
  $token_script_index_prefix,
  $manage_wicked_postup_script = false,
) {

  validate_string($ensure)
  validate_string($token_script_index_prefix)
  validate_bool($manage_wicked_postup_script)
  validate_re($token_script_index_prefix, '^([0-9][0-9])$',
      'token_script_index_prefix must match [0-9][0-9]')
  validate_re($ensure, '^(present|absent)$',
      "ensure must be 'present' or 'absent', got <${ensure}>")
  validate_absolute_path($script_dir)

  $interface = $title

  $custom_token = getvar("::custom_ipv6_token_${interface}")

  if $custom_token != undef and $custom_token != '' {
    $token_real = $custom_token
  }
  else {
    $token_real = getvar("::default_ipv6_token_${interface}")
  }

  if $token_real == undef or $token_real == '' {
    $ensure_real = 'absent'
  }
  else {
    $ensure_real = $ensure
  }

  $token_script_index_prefix_real = $::osfamily ? {
    'Suse'  => '',
    default => $token_script_index_prefix,
  }

  $file = "${script_dir}/${token_script_index_prefix_real}set_ipv6_token-${interface}.sh"

  file { $file:
    ensure  => $ensure_real,
    owner   => 'root',
    group   => 'root',
    mode    => '0744',
    content => template("ipv6token/set_ipv6_token-${::osfamily}.erb"),
  }

  if $token_real != undef and $token_real != '' {
    if $::osfamily == 'Suse' and $manage_wicked_postup_script == true {
      file_line { "wicked_postup_hook-${interface}":
        ensure            => $ensure_real,
        path              => "/etc/sysconfig/network/ifcfg-${interface}",
        line              => "POST_UP_SCRIPT=\"wicked:${token_script_index_prefix_real}set_ipv6_token-${interface}.sh\"",
        match             => '^POST_UP_SCRIPT=',
        match_for_absence => false,
      }
    }
  }

  if $ensure_real == 'present' {
    $command = $::osfamily ? {
      'Suse'  => "${file} post-up ${interface}",
      default => "${file} ${interface} up",
    }

    exec { "set_ipv6_token-${interface}":
      command     => $command,
      refreshonly => true,
      subscribe   => File[$file],
    }
  }
}
