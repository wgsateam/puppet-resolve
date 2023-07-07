# Public: Manage search domain entries in /etc/resolv.conf.
#
# namevar  - The search domain name as a String. With priority.
# :priority - The optional priority of the search domain as an Integer.  If a
#            value between 0 and 5 is provided, the entry will be the first
#            through sixth search domain respectively.
# ensure   - The desired state of the resource as a String.  Valid values are
#            'absent' and 'present' (default: 'present').
#
# Examples
#
#   resolvconf::search {
#     'foo.test.com':
#     'test.com:1':
#   }

define resolv::search (
  $ensure = 'present',
) {
  $_domain = $title.split('/')[-1]
  $_dn = $_domain.split(':')[0]
  $priority = $_domain.split(':')[1]
  if $_dn[0] == '-' {
    $_ensure = 'absent'
    $dn = $_dn[1,-1]
  } else {
    $_ensure = $ensure
    $dn = $_dn
  }
  case $_ensure {
    'present': {
      if $priority.empty() {
        augeas { "${title}: Adding search domain '${dn}' to /etc/resolv.conf":
          lens    => 'resolv.lns',
          incl    => '/etc/resolv.conf',
          context => '/files/etc/resolv.conf',
          changes => "set search/domain[last()+1] ${dn}",
          onlyif  => "match search/domain[.='${dn}'] size==0",
        }
      } else {
        augeas { "${title}: Adding search domain '${dn}' with priority ${priority} to /etc/resolv.conf":
          lens    => 'resolv.lns',
          incl    => '/etc/resolv.conf',
          context => '/files/etc/resolv.conf',
          changes => [
            "rm search/domain[.=${dn}]",
            "ins domain before search/domain[${priority}]",
            "set search/domain[${priority}] ${dn}",
          ],
          onlyif  => "match search/domain[${priority}][.='${dn}'] size==0",
        }
      }
    }
    'absent': {
      if $priority.empty() {
        augeas { "${title}: Removing search domain '${dn}' from /etc/resolv.conf":
          lens    => 'resolv.lns',
          incl    => '/etc/resolv.conf',
          context => '/files/etc/resolv.conf',
          changes => "rm search/domain[.='${dn}']",
        }
      } else {
        augeas { "${title}: Removing search domain '${dn}' from /etc/resolv.conf":
          lens    => 'resolv.lns',
          incl    => '/etc/resolv.conf',
          context => '/files/etc/resolv.conf',
          changes => [
            "rm search/domain[${priority}]",
            "rm search/domain[${priority}]",
            "rm search/domain[${priority}]",
            "rm search/domain[${priority}]",
            "rm search/domain[${priority}]",
            "rm search/domain[${priority}]",
          ],
        }
      }
      augeas { "${title}: Removing search/domains section from /etc/resolv.conf":
        lens    => 'resolv.lns',
        incl    => '/etc/resolv.conf',
        context => '/files/etc/resolv.conf',
        changes => 'rm search',
        onlyif  => 'match search/* size==0',
      }
    }
    default: {
      fail("Invalid ensure value passed to Resolv::Search[${dn}]")
    }
  }
}
