# describe "Facter::Util::Fact" do
describe "default_ipv6_token", :type => :fact do
  before do
    Facter.clear

    # Create facts for dummy interfaces that might not be present on the host
    # where tests are executed so we can stub them later
    interfaces = %w(lo0 docker0 eth0 eth1 eth2 eth3)
    interfaces.each do |interface|
      Facter.add("netmask_#{interface}".to_sym) do
        puts "adding fact for interface #{interface}"
        setcode do
          "#{interface}: 255.255.255.0"
        end
      end
    end
  end

  describe "default ipv6 token" do
    # context "for loopback interface" do
    #
    # end

    context "for multiple interfaces" do
      # before {
      #   allow(Facter.fact(:interfaces)).to receive(:value).and_return("eth0,eth1,eth2")
      #   # allow(Facter.fact(:netmask_eth0)).to receive(:value).and_return("255.255.255.0")
      #   allow(Facter.fact(:netmask_docker0)).to receive(:value).and_return("255.255.400.0")
      #   Facter.fact(:netmask_eth1).stubs(:value).returns("blah!")
      # }
      it do
        allow(Facter.fact(:interfaces)).to receive(:value).and_return("eth0,eth1,eth2")
        # allow(Facter.fact(:netmask_docker0)).to receive(:value).and_return("255.255.400.0")
        allow(Facter.fact(:netmask_eth0)).to receive(:value).and_return("255.255.255.0")
        allow(Facter.fact(:netmask_eth1)).to receive(:value).and_return("255.255.255.128")
        allow(Facter.fact(:netmask_eth2)).to receive(:value).and_return("255.255.254.0")

        #allow(Facter::Util::Resolution).to receive(:exec).with("thrift --version").
          #and_return("Thrift version 0.9.0")
        expect(Facter.fact(:default_ipv6_token_eth0).value).to eql("testing_eth0")
        expect(Facter.fact(:default_ipv6_token_eth1).value).to eql("testing_eth1")
        expect(Facter.fact(:default_ipv6_token_eth2).value).to eql("testing_eth2")
      end
    end
  end
end
