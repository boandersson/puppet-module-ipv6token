# Fact: default_ipv6_token
#
# Purpose:
#
# Create a fact for each available interface containing the default ipv6token
# to use for that interface.
# The token is derived from the ipv4 address of the interface:
# For /23 (or larger), the last two ipv4 octets will be used as a token.
# For /24 (or smaller), only the last ipv4 octet is used.
# For smaller than /24, no token is generated.
#
# A token will be generated for the main interface only (the interface for the
# default route.)
# TODO: What if we have multiple default routes?
#
# Example:
# 192.168.0.100/24 => ::100
# 192.168.10.100/23 => ::10:100
#

require 'facter/util/ip'

puts "**********"
#puts "interfaces: " + Facter.value(:interfaces)
#puts "dummy: " + Facter.value(:dummy)
puts "interfaces: #{Facter.value(:interfaces)}"
puts "netmask_docker0: #{Facter.value(:netmask_docker0)}"
puts "netmask_eth0: #{Facter.value(:netmask_eth0)}"
puts "netmask_eth1: #{Facter.value(:netmask_eth1)}"

Facter.value(:interfaces).split(",").each do |raw_interface|
  # Make a fact for each interface found.
  interface = Facter::Util::IP.alphafy(raw_interface)
  puts "Creating default_ipv6_token fact: interface: #{interface}"

  netmask = Facter::value("netmask_#{interface}".to_sym)
  puts "netmask_#{interface}: #{netmask}"

  if netmask
    cidr = IPAddr.new(netmask).to_i.to_s(2).count("1")
    puts "cidr: #{cidr}"
  else
    puts "netmask for #{interface} not found"
  end

  puts "#{netmask} -> #{cidr}"

  Facter.add('default_ipv6_token_' + interface) do
    setcode do
      "testing_" + interface
    end
  end
end