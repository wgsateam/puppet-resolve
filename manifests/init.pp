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
  $nameservers = undef,
  $search = undef,
  $options = undef
) {
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

  case $::osfamily {
    'Solaris': {
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
    }
    'Debian': {
      file { '/etc/resolvconf/resolv.conf.d/tail':
        ensure  => file,
        content => template('resolv/resolv.conf.erb'),
      }
      ~>
      exec { "resovconfupdate.${nameservers}":
        command     => '/sbin/resolvconf -u',
        refreshonly => true,
      }
    }
    default: {
      if $nameservers {
        resolv::set_nameserver { $nameservers: nameservers => $nameservers }
      }
      if $search {
        augeas { 'set_search':
          lens    => 'resolv.lns',
          incl    => '/etc/resolv.conf',
          context => '/files/etc/resolv.conf',
          changes => "set search ${search_string}",
        }
      }
      if $options {
        augeas { 'set_options':
          lens    => 'resolv.lns',
          incl    => '/etc/resolv.conf',
          context => '/files/etc/resolv.conf',
          changes => "set options ${options_string}",
        }
      }
    }
  }
}

define resolv::set_nameserver ($nameservers) {
  #get current ns index in ns array
  $index = inline_template('<%= @nameservers.sort.index(@title).to_i %>') + 1
  augeas { "set_nameserver_${index}":
    lens    => 'Resolv.lns',
    incl    => '/etc/resolv.conf',
    context => '/files/etc/resolv.conf',
    changes => "set nameserver[${index}] ${title}",
  }
}
