class resolv::fixes {
  if $facts['puppet_vardir'] =~ /^\/opt\/puppetlabs\// and
      $facts['aio_agent_version'] =~ Pattern[/^\d+\.\d+\.\d+/] and
      versioncmp($facts['aio_agent_version'], '7.32.0') < 0 {
    $_file = '/opt/puppetlabs/puppet/share/augeas/lenses/dist/resolv.aug'
    if versioncmp($facts['aio_agent_version'], '7.27.0') > 0 {
      $_opts = ['ip6-dotint','no-ip6-dotint']
    } else {
      $_opts = ['ip6-dotint','no-ip6-dotint','trust-ad']
    }
    $_opts.each |$o| {
      file_line { "glibc_2.31_options_${o}_for_resolv.conf":
        ensure => present,
        path   => $_file,
        after  => '.*Build.flag.*rotate.*',
        line   => "                                     |\"${o}\"",
        match  => ".*|\"${o}\".*",
      }
    }
  }
  # Ensure /etc/resolv.conf is not a symlink
  exec { 'remove_symlink_resolv.conf':
    command => '/bin/sh -c \'/bin/cp --remove-destination "$(/usr/bin/readlink -f /etc/resolv.conf)" /etc/resolv.conf\'',
    onlyif  => [
      '/usr/bin/test -L /etc/resolv.conf',
      '/bin/sh -c \'/usr/bin/test -r "$(/usr/bin/readlink -f /etc/resolv.conf)"\'',
    ],
  }
}
