# Public: Manage the nameserver entries in /etc/resolv.conf
#
# namevar  - The IP address of the nameserver as a String.
#            '<ip>:<priority>' - The optional priority of the nameserver as a Integer.  If a value
#            between 0 and 2 is specified, the nameserver will appear as the
#            first through third nameserver in the file respectively.
#            '<description>/<ip>'
#            full of namevar - '<description>/<ip>:<priority>'
# ensure   - The desired state of the resource as a String.  Valid values are
#           'absent' and 'present' (default: 'present').
#
# Examples
#
#   # 10.0.0.1 and 10.0.0.3 are my nameservers. You can describe description and priority.
#   resolvconf::nameserver { ['10.0.0.1', 'description/10.0.0.3']: }
#
#   # 127.0.0.1 must be the first resolver with description='main_server_for_pdnsd'
#   resolveconf::nameserver { 'main_server_for_pdnsd/127.0.0.1:1': }
#
#   # 10.0.0.2 is an old nameserver that we don't use anymore
#   resolvconf::nameserver { '10.0.0.2':
#     ensure => absent,
#   }

define resolv::nameserver (
  $ensure = 'present',
) {
  $_nameserver_priority = $title.split('/')[-1]
  $_ns = $_nameserver_priority.split(':')[0]
  $_pr = $_nameserver_priority.split(':')[1]
  if $_ns and $_ns[0] == '-' {
    $_ensure = 'absent'
    $nameserver = $_ns[1,-1]
  } else {
    $_ensure = $ensure
    $nameserver = $_ns
  }
  if $_pr {
    $priority = $_pr
    $priority_m = "[${$_pr}]"
  } else {
    $priority = '1'
    $priority_m = ''
  }
  if ! $nameserver.empty() and $_ensure == 'present' {
    $_ch = [
      'set nameserver[last()+1] 0.0.0.0',
      "rm nameserver[.='${nameserver}']",
      "ins nameserver before nameserver[${priority}]",
      "set nameserver[${priority}] ${nameserver}",
      'rm nameserver[.=following-sibling::*]',
      'rm nameserver[position()>3]',
      "rm nameserver[.='0.0.0.0']",
    ]
    $_if = "match nameserver${priority_m}[.='${nameserver}'] size==0"
  } elsif ! $nameserver.empty() and $_ensure == 'absent' {
    $_ch = [
      'set nameserver[last()+1] 0.0.0.0',
      "rm nameserver[.='${nameserver}']",
      'rm nameserver[.=following-sibling::*]',
      'rm nameserver[position()>3]',
      "rm nameserver[.='0.0.0.0']",
    ]
    $_if = "match nameserver${priority_m}[.='${nameserver}'] size>0"
  } else {
    $_ch = [
      'set nameserver[last()+1] 0.0.0.0',
      'rm nameserver[.=following-sibling::*]',
      'rm nameserver[position()>3]',
      "rm nameserver[.='0.0.0.0']",
    ]
    $_if = 'match nameserver size>2'
  }
  if $_ch {
    require resolv::fixes
    augeas { "${title}: Modify nameserver ${nameserver} with priority ${priority} to /etc/resolv.conf":
      lens    => 'resolv.lns',
      incl    => '/etc/resolv.conf',
      context => '/files/etc/resolv.conf',
      changes => $_ch,
      onlyif  => $_if,
    }
  }
}
