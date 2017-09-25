class { '::php':
  ensure       => latest,
  manage_repos => true,
  fpm          => true,
  dev          => true,
  composer     => true,
  pear         => true,
  phpunit      => false,
  extensions   => {
            curl => {},
	    pdo => {},
	  mysql => {}
  }
}
~>
class { 'apache':
  default_mods  => true,
  default_vhost => false,
  # This defaults to 'worker' on debian, setting to false 
  # allows specifying our own.
  mpm_module    =>  false,
}

class { '::mysql::server':
  root_password          => 'secret',
  remove_default_accounts => true
}

mysql::db { 'homestead':
  user => 'joechem',
  password => 'secret',
  host => '%',
  grant => ['SELECT', 'UPDATE', 'CREATE', 'ALTER']
}

class { '::redis':
  bind => '0.0.0.0'
}


include apache::mod::prefork
include apache::mod::php

apache::vhost { 'joechem.dev':
  servername => 'joechem.dev',
  ip => '0.0.0.0',
  port    => '80',
  docroot => '/var/www/public'
}
