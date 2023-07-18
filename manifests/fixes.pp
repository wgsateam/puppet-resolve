class resolv::fixes {
  if $facts['puppet_vardir'] =~ '/opt/puppetlabs' {
    $_file = '/opt/puppetlabs/puppet/share/augeas/lenses/dist/resolv.aug'
  } else {
    $_file = '/usr/share/augeas/lenses/dist/resolv.aug'
  }
  ['ip6-dotint','no-ip6-dotint','trust-ad'].each |$o| {
    file_line { "glibc_2.31_otions_${o}_for_resolf.conf":
      ensure => present,
      path   => $_file,
      after  => '.*Build.flag.*rotate.*',
      line   => "                                     |\"${o}\"",
      match  => ".*\|\"${o}\".*",
    }
  }
}
