# == Class: resolv
#
# Manages Unix resolver
#
# === Parameters
#
# [*nameservers*]
# Array of desired nameservers
# [*search*]
# Array of desired search domains
# [*domain*]
# domain of host
# [*options*]
# Array of desired resolver options
#
# === Examples
#
# You can declare class with resource declaration syntax:
# class { 'resolv': nameservers => ns.example.com }
# but it's better to do it in hiera and just use indlude directive.
#
# === Authors
#
# applewiskey <antony.fomenko@gmail.com>
#
class resolv (
  Variant[Array, Undef] $nameservers = undef,
  Variant[Array, Undef] $search = undef,
  Variant[Array, Undef] $options = undef,
  Variant[String, Undef] $domain = undef,
) {
  if $nameservers {
    $nameservers_array = $nameservers.map |$x| { $x.split('/')[-1].split(':')[0] }
    $nameservers_string = $nameservers_array.join(' ')
  }

  if $domain {
    $domain_string = $domain.split('/')[-1]
  }

  if $search {
    $search_array = $search.map |$x| { $x.split('/')[-1].split(':')[0] }
    $search_string = $search_array.join(' ')
  }

  if $options {
    $options_array = $options.map |$x| { $x.split('/')[-1] }
    $options_string = $options_array.join(' ')
  }

  case $::osfamily {
    'Solaris': {
      if $nameservers {
        exec { "dnsclient.setprop.${nameservers_string}":
          command => "/usr/sbin/svccfg -s network/dns/client setprop config/nameserver = net_address: \'\"${nameservers_string}\"\'; /usr/sbin/svccfg -s network/dns/client refresh",
          unless  => "grep '${nameservers_string}' /etc/resolv.conf",
        }
      }
      if $search {
        exec { "dnsclient.setprop.${search_string}":
          command => "/usr/sbin/svccfg -s network/dns/client setprop config/search = \'\"${search_string}\"\'; /usr/sbin/svccfg -s network/dns/client refresh",
          unless  => "grep '${search_string}' /etc/resolv.conf",
        }
      }

      if $options {
        exec { "dnsclient.setprop.${options_string}":
          command => "/usr/sbin/svccfg -s network/dns/client setprop config/options = \'\"${options_string}\"\'; /usr/sbin/svccfg -s network/dns/client refresh",
          unless  => "grep '${options_string}' /etc/resolv.conf",
        }
      }
    }
    'Debian': {
      package { 'resolvconf':
        ensure => installed,
      }
      ->
      file { '/etc/resolvconf/resolv.conf.d/tail':
        ensure  => file,
        content => template('resolv/resolv.conf.erb'),
      }
      ~>
      exec { 'resovconfupdate':
        command     => '/sbin/resolvconf -u',
        refreshonly => true,
      }
    }
    default: {
      require resolv::fixes
      augeas { 'resolvconf_ext':
        context => '/files/etc/resolv.conf',
        changes => template('resolv/resolv.conf.ext.erb'),
      }
      if $nameservers {
        $ns = reverse(($nameservers.map |$x| { "default/${x}" })[0,2])
      } else {
        $ns = []
      }
      resolv::nameserver { ['default_cleanup/:'] + $ns: }
    }
  }
}
