# Public: Manage the nameserver entries in /etc/resolv.conf
#
# namevar  - The IP address of the nameserver as a String.
# priority - The optional priority of the nameserver as a Integer.  If a value
#            between 0 and 2 is specified, the nameserver will appear as the
#            first through third nameserver in the file respectively.
# ensure   - The desired state of the resource as a String.  Valid values are
#           'absent' and 'present' (default: 'present').
#
# Examples
#
#   # 10.0.0.1 and 10.0.0.3 are my nameservers
#   resolvconf::nameserver { ['10.0.0.1', '10.0.0.3']: }
#
#   # 127.0.0.1 must be the first resolver
#   resolveconf::nameserver { '127.0.0.1:
#     priority => '0',
#   }
#
#   # 10.0.0.2 is an old nameserver that we don't use anymore
#   resolvconf::nameserver { '10.0.0.2':
#     ensure => absent,
#   }
define resolv::nameserver (
  $ensure     = 'present',
) {
  $_nameserver = $title.split('/')[-1]
  $ns = $_nameserver.split(':')[0]
  case $ensure {
    'present': {
      $priority = $_nameserver.split(':')[1]
      if $priority.empty() {
        augeas { "${title}: Adding nameserver ${ns} to /etc/resolv.conf":
          lens    => 'resolv.lns',
          incl    => '/etc/resolv.conf',
          context => '/files/etc/resolv.conf',
          changes => [
            'ins nameserver after nameserver[last()]',
            "set nameserver[last()] ${ns}",
          ],
          onlyif  => "match nameserver[.='${ns}'] size==0",
        }
      } else {
        augeas { "${title}: Adding nameserver ${ns} with priority ${priority} to /etc/resolv.conf":
          lens    => 'resolv.lns',
          incl    => '/etc/resolv.conf',
          context => '/files/etc/resolv.conf',
          changes => [
            "rm nameserver[.='${ns}']",
            "ins nameserver before nameserver[${priority}]",
            "set nameserver[${priority}] ${ns}",
          ],
          onlyif  => "match nameserver[${priority}][.='${ns}'] size==0",
        }
      }
    }
    'absent': {
      augeas { "${title}: Removing nameserver ${ns} from /etc/resolv.conf":
        lens    => 'resolv.lns',
        incl    => '/etc/resolv.conf',
        context => '/files/etc/resolv.conf',
        changes => [
          "rm nameserver[.='${ns}']",
        ],
      }
    }
    default: {
      fail("Invalid ensure value passed to Resolv::Nameserver[${ns}]")
    }
  }
}
