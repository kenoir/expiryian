require 'openssl'
require 'trollop'
require 'active_support/time'
require 'net/http'

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

# Setup proxy
if(ENV['http_proxy'].nil?)
  http_client = Net::HTTP
else
  proxy_uri = URI(ENV['http_proxy'])
  http_proxy = Net::HTTP::Proxy(proxy_uri.host,proxy_uri.port)
end

# Choose certificate location
if(opts[:peer_cert])
  uri = URI(ARGV[0])
  response = http_proxy.get_response(uri)

  certificate = response.peer_cert
else
  certificate = OpenSSL::X509::Certificate.new open(ARGV[0])
end

# Check Expiry
certificate_expired = certificate.not_after < Time.new() + opts[:days].days

# Put some informatio about cert status and exit
if certificate_expired
  puts "Warning! Certificate expires on: #{certificate.not_after}"
  exit 1
else
  puts "Looks fine. Certificate expires on: #{certificate.not_after}"
  exit 0
end
