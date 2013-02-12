require 'date'
require 'openssl'
require 'trollop'
require 'open-uri'
require 'active_support/time'

opts = Trollop::options do
  version "Expiryion Certificate Check 0.1 (c) 2012 Robert Kenny"
  banner <<-EOS
Expiryion Certificate Check will tell you if an X509 Certificate is about to expire.

Usage:
       expiryion [options] <filename_or_url>

Example(s):

      expiryion --days 3 http://www.example.com/mycert.pem
      expiryion mycert.pem

where [options] are:
EOS
  opt :days, "Days to offset expiry check", :default => 5
end
Trollop::die :days, "must be a whole positive number" if ((not opts[:days].is_a? Integer) or (opts[:days] < 0))
Trollop::die "You must specify a certificate location" if ARGV[0].nil?

certificate = OpenSSL::X509::Certificate.new open(ARGV[0])
certificate_expired = certificate.not_after < Time.new() + opts[:days].days

exit 1 if certificate_expired
