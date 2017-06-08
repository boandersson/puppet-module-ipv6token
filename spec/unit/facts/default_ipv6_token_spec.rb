# describe "Facter::Util::Fact" do
describe "default_ipv6_token", :type => :fact do
  before { Facter.clear }

  describe "default ipv6 token" do
    before(:each) do
      # Create facts for dummy interfaces that might not be present on the host
      # where tests are executed so we can stub them later
      interfaces = "lo,eth0,eth1,eth2"
      interfaces.split(",").each do |interface|
        Facter.add("netmask_#{interface}".to_sym) { setcode { "255.255.255.0" } }
        Facter.add("ipaddress_#{interface}".to_sym) { setcode { "192.168.0.1" } }
      end

      allow(Facter.fact(:interfaces)).to receive(:value).and_return("lo,eth0,eth1,eth2")
    end

    context "handles invalid netmask" do
      it do
        allow(Facter.fact(:ipaddress_eth0)).to receive(:value).and_return("192.168.0.1")
        allow(Facter.fact(:netmask_eth0)).to receive(:value).and_return("255.255.255")

        expect(Facter.fact(:default_ipv6_token_eth0).value).to be_nil
      end
    end

    context "handles missing netmask" do
      it do
        allow(Facter.fact(:ipaddress_eth0)).to receive(:value).and_return("192.168.0.1")
        allow(Facter.fact(:netmask_eth0)).to receive(:value).and_return(nil)

        expect(Facter.fact(:default_ipv6_token_eth0).value).to be_nil
      end
    end

    context "handles invalid ipv4 address" do
      it do
        allow(Facter.fact(:ipaddress_eth0)).to receive(:value).and_return("192.168.0")
        allow(Facter.fact(:netmask_eth0)).to receive(:value).and_return("255.255.255.0")

        expect(Facter.fact(:default_ipv6_token_eth0).value).to be_nil
      end
    end

    context "handles missing ipv4 address" do
      it do
        allow(Facter.fact(:ipaddress_eth0)).to receive(:value).and_return(nil)
        allow(Facter.fact(:netmask_eth0)).to receive(:value).and_return("255.255.255.0")

        expect(Facter.fact(:default_ipv6_token_eth0).value).to be_nil
      end
    end

    context "for loopback interface" do
      it do
        allow(Facter.fact(:ipaddress_lo)).to receive(:value).and_return("127.0.0.1")
        allow(Facter.fact(:netmask_lo)).to receive(:value).and_return("255.0.0.0")

        expect(Facter.fact(:default_ipv6_token_lo)).to be_nil
      end
    end

    context "handles 23-mask" do
      it do
        allow(Facter.fact(:ipaddress_eth0)).to receive(:value).and_return("192.168.0.1")
        allow(Facter.fact(:netmask_eth0)).to receive(:value).and_return("255.255.254.0")   # /23

        expect(Facter.fact(:default_ipv6_token_eth0).value).to eql("::0:1")
      end
    end

    context "handles 24-mask" do
      it do
        allow(Facter.fact(:ipaddress_eth0)).to receive(:value).and_return("192.168.0.1")
        allow(Facter.fact(:netmask_eth0)).to receive(:value).and_return("255.255.255.0")   # /24

        expect(Facter.fact(:default_ipv6_token_eth0).value).to eql("::1")
      end
    end

    context "handles 25-mask" do
      it do
        allow(Facter.fact(:ipaddress_eth0)).to receive(:value).and_return("192.168.0.1")
        allow(Facter.fact(:netmask_eth0)).to receive(:value).and_return("255.255.255.128") # /25

        expect(Facter.fact(:default_ipv6_token_eth0).value).to eql("::1")
      end
    end

    context "handles single interface" do
      it do
        allow(Facter.fact(:interfaces)).to receive(:value).and_return("eth0")
        allow(Facter.fact(:ipaddress_eth0)).to receive(:value).and_return("192.168.0.1")
        allow(Facter.fact(:netmask_eth0)).to receive(:value).and_return("255.255.255.0")   # /24

        expect(Facter.fact(:default_ipv6_token_eth0).value).to eql("::1")
      end
    end

    context "handles multiple interfaces" do
      it do
        allow(Facter.fact(:ipaddress_eth0)).to receive(:value).and_return("192.168.0.1")
        allow(Facter.fact(:ipaddress_eth1)).to receive(:value).and_return("192.168.100.100")
        allow(Facter.fact(:ipaddress_eth2)).to receive(:value).and_return("192.168.50.50")

        allow(Facter.fact(:netmask_eth0)).to receive(:value).and_return("255.255.255.0")   # /24
        allow(Facter.fact(:netmask_eth1)).to receive(:value).and_return("255.255.255.128") # /25
        allow(Facter.fact(:netmask_eth2)).to receive(:value).and_return("255.255.254.0")   # /23

        expect(Facter.fact(:default_ipv6_token_eth0).value).to eql("::1")
        expect(Facter.fact(:default_ipv6_token_eth1).value).to eql("::100")
        expect(Facter.fact(:default_ipv6_token_eth2).value).to eql("::50:50")
      end
    end
  end
end
