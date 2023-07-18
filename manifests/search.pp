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
  $_domain_priority = $title.split('/')[-1]
  $_dn = $_domain_priority.split(':')[0]
  $_pr = $_domain_priority.split(':')[1]
  if $_dn[0] == '-' {
    $_ensure = 'absent'
    $domain = $_dn[1,-1]
  } else {
    $_ensure = $ensure
    $domain = $_dn
  }
  if ! $_pr.empty() {
    $priority = $_pr
    $priority_m = "[${$_pr}]"
  } else {
    $priority = '1'
    $priority_m = ''
  }
  if ! $domain.empty() and $_ensure == 'present' {
    $_ch = [
      'set search/domain[last()+1] tmp',
      "rm search/domain[.='${domain}']",
      "ins domain before search/domain[${priority}]",
      "set search/domain[${priority}] ${domain}",
      "rm search/domain[.='tmp']",
    ]
    $_if = "match search/domain${priority_m}[.='${domain}'] size==0"
  } elsif ! $domain.empty() and $_ensure == 'absent' {
    $_ch = "rm search/domain[.='${domain}']"
    $_if = "match search/domain${priority_m}[.='${domain}'] size>0"
  }
  if $_ch {
    require resolv::fixes
    augeas { "${title}: Modify search/domain ${domain} with priority ${priority} to /etc/resolv.conf":
      lens    => 'resolv.lns',
      incl    => '/etc/resolv.conf',
      context => '/files/etc/resolv.conf',
      changes => $_ch,
      onlyif  => $_if,
    }
  }
}
