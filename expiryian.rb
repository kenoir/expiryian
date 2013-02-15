require 'trollop'
require 'pry'

opts = Trollop::options do
  version "Expiryion Certificate Check 0.1 (c) 2012 Robert Kenny"
  banner <<-EOS
Expiryion Certificate Check will tell you if an X509 Certificate is about to expire.

Usage:
       expiryian [options] <filename_or_url>

Example(s):

      expiryian --days 3 http://www.example.com/mycert.pem
      expiryian --days 3 https://www.example.com
      expiryian mycert.pem

where [options] are:
EOS
  opt :peer_cert, "Get the peer cert from a HTTPS Connection"
  opt :days, "Days to offset expiry check", :default => 5
end
Trollop::die :days, "must be a whole positive number" if ((not opts[:days].is_a? Integer) or (opts[:days] < 0))
Trollop::die "You must specify a certificate location" if ARGV[0].nil?

module Experyian 
  module CLI
    require 'active_support/time'

    def certificate_location
      ARGV[0] || "certificate.pem"
    end

    def peer_cert?
      @opts[:peer_cert]
    end

    def time_to_expiry 
      @opts[:days].days
    end

    def show(message)
      puts message
    end

    def exit_on
      exit 1 if yield
      exit 0
    end
      
  end

  module Network 
    require 'net/http'
    require 'uri'

    def proxy_uri
      @proxy_uri ||= URI(ENV['http_proxy'])
    end
    
    def http_client
      proxy_uri ? Net::HTTP::Proxy(proxy_uri.host,proxy_uri.port) : Net::HTTP 
    end
  end 

  module Certificate
    require 'openssl'

    class OpenSSL::X509::Certificate
      def expires_in?(seconds)
        not_after < Time.new() + seconds 
      end
    end
    
    def peer_cert_at(uri)
      parsed_uri = URI(uri)
      client = http_client.new(parsed_uri.host, parsed_uri.port)
      client.use_ssl = true
    
      peer_cert = client.start do
        client.peer_cert
      end

      OpenSSL::X509::Certificate.new peer_cert 
    end
    
    def cert_at(location)
      OpenSSL::X509::Certificate.new open(location)
    end
  end

  class Application 
    include CLI
    include Network
    include Certificate

    def initialize(opts)
      @opts = opts
    end

    def certificate
      if peer_cert?
        peer_cert_at certificate_location
      else
        cert_at certificate_location
      end
    end

    def certificate_expired?
      certificate.expires_in? time_to_expiry
    end

    def check
      if certificate_expired?
        show("Warning! Certificate expires on: #{certificate.not_after}")
      else
        show("Looks fine. Certificate expires on: #{certificate.not_after}")
      end

      exit_on { certificate_expired? } 
    end
  end

  def check(opts)
    Application.new(opts).check
  end

  module_function :check
end  

Experyian.check(opts)
