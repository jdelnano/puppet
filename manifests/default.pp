class { '::php':
  ensure       => latest,
  manage_repos => true,
  fpm          => true,
  dev          => true,
  composer     => true,
  pear         => true,
  phpunit      => false,
}

class { '::mysql::server':
  root_password          => 'strongpassword',
  remove_default_accounts => true
}

class { '::redis':
  bind => '0.0.0.0'
}

class { 'apache':
  default_mods  => true,
  default_vhost => false,
  # This defaults to 'worker' on debian, setting to false 
  # allows specifying our own.
  mpm_module    =>  false,
}

include apache::mod::prefork
include apache::mod::php

apache::vhost { 'joechem.dev':
  servername => 'joechem.dev',
  ip => '127.0.0.1',
  port    => ['80','8080'],
  docroot => '/var/www/public'
}
