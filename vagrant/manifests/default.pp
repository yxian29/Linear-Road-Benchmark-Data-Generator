Exec {
  path => ["/usr/bin", "usr/local/bin", "/bin"],
}

exec { 'update':
  command => "apt-get update",
}

$enhancers = [ "build-essential", "gcc-multilib", "vim", "puppet", "perl"]
package { $enhancers: ensure =>  "installed" }

group { "wheel":
  ensure => "present",
}

user { 'vagrant':
  gid        => "wheel",
  managehome => true,
  password   => "123",
  require    => Group["wheel"],
}

exec { "/bin/echo \"%wheel  ALL=(ALL) ALL\" >> /etc/sudoers":
   require => Group["wheel"],
}

class { 'postgresql::globals':
  manage_package_repo => true,
  version             =>  '9.3',
}->
class { 'postgresql::server': }

postgresql::server::db { 'hellolrb':
  user     => 'vagrant',
  password => postgresql_password('vagrant', 'hellopwd'),
  grant    => 'ALL',
  require  => User['vagrant'],
}

postgresql::server::role { 'vagrant':
  superuser => true,
  require  => User['vagrant'],
}


file { '/tmp/.s.PGSQL.5432':
  ensure => 'link',
  target => '/var/run/postgresql/.s.PGSQL.5432',
  require => Class['postgresql::server'],
}

package { 'libso':
  provider => 'dpkg',
  source   => '/vagrant_data/libstdc++2.10-glibc2.2_2.95.4-27_i386.deb',
}

include cpan
$cpan_modules = ["DBI", "Math::Random", "FileHandle", "DBD::PgPP"]
cpan { $cpan_modules:
  ensure  => present,
  require => Class['::cpan'],
  force   =>  true,
}

exec {'extract_mitsim':
  command => "tar -zxvf /vagrant_data/mitsim.tar.gz -C /opt/",
}

file { "/opt/data":
  ensure  => "directory",
  mode    => "777",
  group   => "wheel",
  owner   => 'vagrant',
  require => User['vagrant'],
}

file { "/opt/mitsim.config":
  ensure  => 'file',
  source  => '/vagrant_data/mitsim.config',
  replace => 'true',
  group   => "wheel",
  owner   => 'vagrant',
  require => [Exec["extract_mitsim"],User['vagrant'] ]
}

file { "/opt/DuplicateCars.pl":
  ensure  => 'file',
  source  => '/vagrant_data/DuplicateCars.pl',
  replace => 'true',
  mode    => '700',
  group   => "wheel",
  owner   => 'vagrant',
  require => [Exec["extract_mitsim"],User['vagrant'] ]
}
