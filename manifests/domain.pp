# Public: Manage the 'domain' entry in /etc/resolv.conf
#
# namevar - The value String to set the 'domain' entry in /etc/resolv.conf to.
# ensure  - The state of the resource as a String.  Valid values are 'absent'
#           and 'present' (default: 'present').
#
# Example
#
#   # Add the 'domain' entry to /etc/resolv.conf and set it to 'foo.bar.com'
#   resolvconf::domain { 'foo.bar.com': }
#
#   # Remove the 'domain' entry from /etc/resolv.conf
#   resolvconf::domain { 'test.bar.com':
#     ensure => absent,
#   }
define resolv::domain (
  $ensure = 'present',
) {
  $_domain = $title.split('/')[-1]
  case $ensure {
    'present': {
      augeas { "${title}: Setting domain in /etc/resolv.conf to ${_domain}":
        lens    => 'resolv.lns',
        incl    => '/etc/resolv.conf',
        context => '/files/etc/resolv.conf',
        changes => [
          'touch domain',
          "set domain ${_domain}",
        ],
        onlyif  => "match /files/etc/resolv.conf/domain[.='${_domain}'] size==0",
      }
    }
    'absent': {
      augeas { "${title}: Removing domain from /etc/resolv.conf":
        lens    => 'resolv.lns',
        incl    => '/etc/resolv.conf',
        context => '/files/etc/resolv.conf',
        changes => 'rm domain',
      }
    }
    default: {
      fail("Invalid ensure value passed to Resolv::Domain[${_domain}]")
    }
  }
}