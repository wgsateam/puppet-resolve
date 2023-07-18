# Public: Manage options entries in /etc/resolv.conf
#
# namevar:value - The name of the option to be managed as a String.
#           The value of the option as a String.  This is only required when
#           managing options that take a value ('ndots', 'timeout', and
#           'attempts').
# ensure  - The desired state of the resource as a String.  Valid values are
#           'absent' and 'present' (default: 'present').
#
# Examples
#
#   # Set the resolver timeout to 1 second
#   resolvconf::option { 'timeout:1': }
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
  $_option_value = $title.split('/')[-1]
  $_option = $_option_value.split(':')[0]
  $value = $_option_value.split(':')[1]
  if $_option[0] == '-' {
    $_ensure = 'absent'
    $option = $_option[1,-1]
  } else {
    $_ensure = $ensure
    $option = $_option
  }
  if ! $option.empty() and $_ensure == 'present' {
    $_ch = $value.empty() ? {
      true    => "touch options/${option}",
      default => "set options/${option} ${value}",
    }
    $_if = "match options/${option} size==0"
  } elsif ! $option.empty() and $_ensure == 'absent' {
    $_ch = "rm options/${option}"
    $_if = "match options/${option} size>0"
  }
  if $_ch {
    require resolv::fixes
    augeas { "${title}: Modify option '${option}' with value ${value} to /etc/resolv.conf":
      lens    => 'resolv.lns',
      incl    => '/etc/resolv.conf',
      context => '/files/etc/resolv.conf',
      changes => $_ch,
      onlyif  => $_if,
    }
  }
}
