# Expiryian Certificate Check

Simple script whose exit status tells you if an X509 Certificate is about to expire.

    Usage:
           expiryian [options] <filename_or_url>
    
    Example(s):
    
          expiryian --days 3 http://www.example.com/mycert.pem
          expiryian mycert.pem

    where [options] are:
      --days, -d <i>:   Days to offset expiry check (default: 5)
       --version, -v:   Print version and exit
          --help, -h:   Show this message 
