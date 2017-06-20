# Fact: default_ipv6_token
#
# Purpose:
#
# Create a fact for each available interface (except lo) containing the default
# ipv6token to use for that interface.
# The token is derived from the ipv4 address of the interface:
# For /23 (or larger), the last two ipv4 octets will be used as a token.
# For /24 (or smaller), only the last ipv4 octet is used.
# For smaller than /24, no token is generated.
#
# Example:
# 192.168.0.100/24 => ::100
# 192.168.10.100/23 => ::10:100
#
Facter.value(:interfaces).split(",").reject { |r_if| r_if == 'lo' }.each do |raw_interface|
  # Make a fact for each interface found.
  interface = Facter::Util::IP.alphafy(raw_interface)

  Facter.add('default_ipv6_token_' + interface) do
    confine :kernel => 'Linux'
    setcode do
      netmask = Facter::value("netmask_#{interface}".to_sym)
      ipv4_address = Facter::value("ipaddress_#{interface}".to_sym)

      if netmask && ipv4_address
        begin
          cidr = IPAddr.new(netmask).to_i.to_s(2).count("1")
          IPAddr.new(ipv4_address) # Validate ipv4 address
          ipv4_octets = ipv4_address.split(".")

          if cidr >= 24
            "::#{ipv4_octets[3]}"
          else
            "::#{ipv4_octets[2]}:#{ipv4_octets[3]}"
          end
        rescue
          nil
        end
      end
    end
  end
end
