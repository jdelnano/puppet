class roles::joechem {
    package { 'git':
        ensure => 'installed',
    }
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
          mysql => {},
          mbstring => {},
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

    include apache::mod::prefork
    include apache::mod::php
    include apache::mod::rewrite

    $vhost = $facts['ec2_metadata'] ? {
      true => 'joechem.io',
      default => 'joechem.dev'
    }

    apache::vhost { "${vhost}" :
      servername => "${vhost}",
      ip         => '0.0.0.0',
      port       => '80',
      docroot    => '/var/www/joechem/public',
      override   =>  ['All'],
    }

    unless $facts['ec2_metadata'] 
    {
        class { '::mysql::server':
          root_password          => 'secret',
          remove_default_accounts => true,
          override_options => {
            mysqld => { bind-address => '127.0.0.1'} #Allow remote connections
          },
        }

        mysql::db { 'homestead':
          user => 'joechem',
          password => 'secret',
          host => '%',
          grant => ['SELECT', 'UPDATE', 'CREATE', 'ALTER']
        }

        mysql::db { 'testing':
          user => 'joechem',
          password => 'secret',
          host => '%',
          grant => ['SELECT', 'UPDATE', 'CREATE', 'ALTER']
        }

        class { '::redis':
          bind => '0.0.0.0'
        }

    }
}
