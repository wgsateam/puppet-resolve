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
  Variant[Array, Undef] $options = undef
) {
  if $nameservers {
    $nameservers_string = join($nameservers, ' ')
  }

  if $search {
    $search_string = join($search, ' ')
  }

  if $options {
    $options_string = join($options, ' ')
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
      exec { "resovconfupdate":
        command     => '/sbin/resolvconf -u',
        refreshonly => true,
      }
    }
    default: {
      if $nameservers {
        resolv::set_nameserver { $nameservers: }
      }
      if $search {
        file_line { 'set_search':
          path  => '/etc/resolv.conf',
          line  => "search ${search_string}",
          match => '^search',
        }
      }
      if $options {
        file_line { 'set_options':
          path  => '/etc/resolv.conf',
          line  => "options ${options_string}",
          match => '^options',
        }
      }
    }
  }
}

define resolv::set_nameserver {
  file_line { "set_ns_${title}":
    path  => '/etc/resolv.conf',
    line  => "nameserver ${title}",
    match => "nameserver ${title}",
  }
}
