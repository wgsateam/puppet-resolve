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
# [*options*]
# Array of desired resolver options
#
# === Examples
#
# You can declare class with resource declaration syntax:
# class { '::resolv': nameservers => ns.example.com }
# but it's better to do it in hiera and just use indlude directive.
#
# === Authors
#
# applewiskey <antony.fomenko@gmail.com>
#
class resolv (
  $nameservers = $resolv::params::nameservers,
  $search      = $resolv::params::search,
  $options     = $resolv::params::options
) inherits resolv::params {
  if $nameservers {
    validate_array($nameservers)
    $nameservers_string = join($nameservers, ' ')
  }

  if $search {
    validate_array($search)
    $search_string = join($search, ' ')
  }

  if $options {
    validate_array($options)
    $options_string = join($options, ' ')
  }

  $config_path = $::osfamily ? {
    'Debian' => '/etc/resolvconf/resolv.conf.d/tail',
    default  => '/etc/resolv.conf',
  }

  $notify = $::osfamily ? {
    'Debian' => Exec['resovconfupdate'],
    default  => undef,
  }

  if $::osfamily == 'Solaris' {
    if $nameservers {
      exec { "dnsclient.setprop.${nameservers_string}":
        command => "/usr/sbin/svccfg -s network/dns/client setprop config/nameserver = net_address: \'\"${nameservers_string}\"\'; /usr/sbin/svccfg -s network/dns/client refresh",
        unless  => "/usr/bin/svcprop -p config/nameserver network/dns/client | grep ${nameservers_string}",
      }
    }
    if $search {
      exec { "dnsclient.setprop.${search_string}":
        command => "/usr/sbin/svccfg -s network/dns/client setprop config/search = \'\"${search_string}\"\'; /usr/sbin/svccfg -s network/dns/client refresh",
        unless  => "/usr/bin/svcprop -p config/search network/dns/client | grep ${search_string}",
      }
    }

    if $options {
      exec { "dnsclient.setprop.${options_string}":
        command => "/usr/sbin/svccfg -s network/dns/client setprop config/options = \'\"${options_string}\"\'; /usr/sbin/svccfg -s network/dns/client refresh",
        unless  => "/usr/bin/svcprop -p config/options network/dns/client | grep ${options_string}",
      }
    }
  } else {
    unless empty($nameservers) {
      file { $config_path:
        ensure  => file,
        content => template('resolv/resolv.conf.erb'),
        notify  => $notify,
      }
      exec { "resovconfupdate.${nameservers}":
        command     => '/sbin/resolvconf -u',
        refreshonly => true,
      }
    }
  }
}
