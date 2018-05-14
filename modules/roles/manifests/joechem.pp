class roles::joechem {
    # WITHOUT MySQL (using RDS with AWS)
    # Install PHP7.1
    package { 'git':
        ensure => 'installed',
    }
    class { '::php::globals':
      php_version => '7.1',
      config_root => '/etc/php/7.1'
    }->
    class { '::php':
      ensure       => latest,
      manage_repos => true,
      package_prefix => 'php7.1-',
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

    # Nginx Config
    class { 'nginx':
      manage_repo => true,
      package_source => 'nginx-mainline'
    }

    file { "/var/www/":
      ensure => directory,
      recurse => true,
      force => true,
      require => Package["nginx"],
    }

    file { "/var/www/html":
      ensure => absent,
      recurse => true,
      force => true,
    }

    file { "/etc/nginx/sites-available/default":
      ensure => absent,
      force  => true,
    }

    file { "/etc/nginx/sites-enabled/default":
      ensure => absent,
      force  => true,
    }

  nginx::resource::server { $facts['hostname']:
    ensure                => present,
    ssl                   => true,
    listen_port           => 80,
    ssl_port              => 443,
    ssl_cert              => '/etc/nginx/ssl/server.crt',
    ssl_key               => '/etc/nginx/ssl/server.key',
    listen_options        => default_server,
    ipv6_enable           => true,
    server_name           => [ 'joechem.io', 'www.joechem.io' ],
    www_root              => '/var/www/joechem/public',
    index_files           => [ 'index.php', 'index.html', 'index.htm' ],
    use_default_location  => false,
    raw_append => ['if ( $http_x_forwarded_proto = \'http\' ) { return 302 https://$host$request_uri; }'],
  }

  nginx::resource::location { "/":
    ensure            => present,
    server            => $facts['hostname'],
    #ssl               => true,
    #ssl_only          => true,
    try_files         => [ '$uri', '$uri/', '/index.php?$query_string' ],
    index_files       => [],
  }

    nginx::resource::location { "~ \.php$":
      ensure              => present,
      server              => $facts['hostname'],
      #ssl                 => true,
      #ssl_only            => true,
      try_files           => [ '$uri', '=404' ],
      index_files         => [],
      include             => [ 'fastcgi_params' ],
      location_cfg_append => {
        fastcgi_split_path_info => '^(.+\.php)(/.+)$',
        fastcgi_param           => { 'SCRIPT_FILENAME' => '$document_root$fastcgi_script_name' },
        fastcgi_pass            => 'unix:/run/php/php7.1-fpm.sock',
        fastcgi_index           => 'index.php'
    }
  }

    nginx::resource::location { "~ /\.ht":
      ensure          => present,
      server          => $facts['hostname'],
      ssl             => true,
      ssl_only        => true,
      location_deny   => ['all'],
      index_files     => []
  }
    
    class { '::mysql::server':
      root_password          => 'secret',
      remove_default_accounts => true,
    }

    mysql::db { 'joechem_master':
      user => 'joechem',
      password => 'secret',
      dbname => 'joechem_master',
      host => '%',
      grant => ['SELECT', 'UPDATE', 'CREATE', 'ALTER', 'DELETE']
    }
 }
