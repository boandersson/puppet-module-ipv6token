## Overview

Puppet module for configuring IPv6 tokenized interface identifiers

[![Build Status](https://travis-ci.org/boandersson/puppet-module-ipv6token.svg?branch=master)](https://travis-ci.org/boandersson/puppet-module-ipv6token)

## Compatibility

This module is supported on RedHat 6/7 and Suse 12.
On RedHat 7, network interfaces must be managed by NetworkManager and on Suse 12, the interfaces must be managed by wicked.

## Module Description

This module uses the ip command of the iproute2 package to configure IPv6 tokenized interface identifiers.
The token to use for each interface is provided by facts. The module will create a separate fact (`default_ipv6_token_<if>`) for each interface found on the system where each fact will contain the token to use for that specific interface.
The default method will determine the token from the configured IPv4 address. For /24 and smaller networks, the token will be based on the last IPv4 octet.
For /23 or larger networks, the last two IPv4 octets will be used.

Example:

IPv4 on eth0 | default_ipv6_token_eth0
-------------|------------------------
192.168.50.50/23   | ::50:50
192.168.0.1/24     | ::1
192.168.100.100/25 | ::100

To override this behavior, install a custom fact called `custom_ipv6_token_<if>` providing the desired token to use.

On RedHat 6, the module uses the `/sbin/ifup-local` hook for configuring IPv6 tokens directly with the ip command. `/sbin/ifup-local` is executed by the network service so the tokens will be automatically applied at boot or when restarting the network service.
The script that performs the actual configuration will be installed in `/etc/sysconfig/network-scripts/ifup-local.d`. The `/sbin/ifup-local` script provided by this module will execute all scripts found in that directory.

On RedHat 7, NetworkManager dispatcher scripts are installed in `/etc/NetworkManager/dispatcher.d` to perform the configuration.

On Suse, the wicked network management utility is used by adding a `POST_UP_SCRIPT` configuration per interface in the `/etc/sysconfig/network/ifcfg-<if>` file. The actual token configuration script is installed in `/etc/wicked/scripts`.

See the RedHat documentation [configuring IPv6 tokenized interface identifiers](https://access.redhat.com/documentation/en-US/Red_Hat_Enterprise_Linux/6/html/Deployment_Guide/s2-Configuring_IPv6_Tokenized_Interface_Identifiers.html) for general details about IPv6 tokens.

## Parameters

ensure
------
Valid values are present or absent. This parameter controls the presence of the hooks and scripts.
Note that once set, an IPv6 token cannot be removed, only changed. Any configured tokens will thus not be removed.

- *Default*: 'present'

exclude_interfaces
------------------
An array containing interface names for which ipv6 tokens should not be configured.

- *Default*: []

manage_ifup_local
-----------------
This parameter is used on RedHat 6 systems only.
It controls whether or not the module should control the main `/sbin/ifup-local` hook. The script in `/etc/sysconfig/network-scripts/ifup-local.d` will be installed regardless but this setting allows for controlling `/sbin/ifup-local` through other means.
The default is false to avoid overwriting any previously existing script.

- *Default*: false

manage_wicked_postup_script
---------------------------
This parameter is used on Suse 12 systems only.
It controls whether or not the module should configure the
`POST_UP_SCRIPT` section in the `ifcfg(5)` file for each
interface with a token configured.
Without this setting, IPv6 tokens will not be configured at boot
or when restarting the network service.
Note that if enabling this setting, any existing `POST_UP_SCRIPT` configuration will be overwritten. For this reason, it defaults to false.

- *Default*: false

manage_main_if_only
-------------------
Specifies if tokens should be configured for all interfaces or only for the main interface. The main interface is determined to be the interface connected to the default gw. The main interface is determined by the main_interface fact from the [juliengk-stdlibplus](https://github.com/juliengk/puppet-stdlibplus) module.

- *Default*: true

token_script_index_prefix
-------------------------
This setting is used on RedHat systems only and controls the index prefix of the hook script. The prefix can be used to change execution order in case there are multiple scripts executed for an interface.
Note that changing this value will not remove any previously installed script.
Valid values are [0-9][0-9].

- *Default*: '90'
