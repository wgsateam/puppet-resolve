class resolv::fixes {
  if $facts['puppet_vardir'] =~ '/opt/puppetlabs' {
    $_file = '/opt/puppetlabs/puppet/share/augeas/lenses/dist/resolv.aug'
  } else {
    $_file = '/usr/share/augeas/lenses/dist/resolv.aug'
  }
  if versioncmp($facts['aio_agent_version'], '7.28.0') < 0 {
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
      match  => ".*\|\"${o}\".*",
    }
  }
}
