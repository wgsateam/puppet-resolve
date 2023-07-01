# Public: Manage options entries in /etc/resolv.conf
#
# namevar - The name of the option to be managed as a String.
# value   - The value of the option as a String.  This is only required when
#           managing options that take a value ('ndots', 'timeout', and
#           'attempts').
# ensure  - The desired state of the resource as a String.  Valid values are
#           'absent' and 'present' (default: 'present').
#
# Examples
#
#   # Set the resolver timeout to 1 second
#   resolvconf::option { 'timeout':
#     value => '1',
#   }
#
#   # Attempt AAAA lookups before A
#   resolvconf::option { 'inet6': }
#
#   # Disable debug mode
#   resolvconif::option { 'debug':
#     ensure => 'absent',
#   }

define resolv::option (
  $ensure = 'present',
) {
  $_option = $title.split('/')[-1]
  $opt = $_option.split(':')[0]
  case $ensure {
    'present': {
      $_value = $_option.split(':')[1]
      if $_value.empty() {
        augeas { "${title}: Adding option '${opt}' to /etc/resolv.conf":
          lens    => 'resolv.lns',
          incl    => '/etc/resolv.conf',
          context => '/files/etc/resolv.conf',
          changes => [
            'touch options',
            "touch options/${opt}",
          ],
          onlyif  => "match options/${opt} size==0",
        }
      } else {
        augeas { "${title}: Adding option '${opt}' with value ${_value} to /etc/resolv.conf":
          lens    => 'resolv.lns',
          incl    => '/etc/resolv.conf',
          context => '/files/etc/resolv.conf',
          changes => [
            'touch options',
            "set options/${opt} ${_value}",
          ],
          onlyif  => "match options/${opt} size==0",
        }
      }
    }
    'absent': {
      augeas { "${title}: Removing option '${opt}' from /etc/resolv.conf":
        lens    => 'resolv.lns',
        incl    => '/etc/resolv.conf',
        context => '/files/etc/resolv.conf',
        changes => "rm options[.='${opt}']",
        onlyif  => 'match options size==0',
      }
    }
    default: {
      fail("Invalid ensure value passed to Resolv::Option[${opt}]")
    }
  }
}
