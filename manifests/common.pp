# == Class: bacula::common
#
# This class enforces common resources needed by all
# bacula components
#
# === Actions:
# * Enforce the bacula user and groups exist
# * Enforce the +/var/spool/bacula+ is a director and +/var/lib/bacula+
#   points to it
#
# === Sample Usage:
#
#  class { 'bacula::common': }
#
class bacula::common(
  $packages         = undef,
  $manage_db_tables = true,
  $db_backend       = 'sqlite',
  $db_user          = '',
  $db_database      = 'bacula',
  $db_password      = '',
  $db_port          = '3306',
  $db_host          = 'localhost',
  $is_client        = true,
  $is_director      = false,
  $is_storage       = false,
  $manage_console   = false,
  $manage_bat       = false
) {
  include bacula::params

  if $packages {
    $packages_notify = $manage_db_tables ? {
      true    => Exec['make_db_tables'],
      default => undef,
    }
    package { $packages:
      ensure => installed,
      notify => $packages_notify,
    }
  }

# Specify the user and group are present before we create files.
  group { 'bacula':
    ensure => present,
  }

  user { 'bacula':
    ensure  => present,
    gid     => 'bacula',
    require => Group['bacula'],
  }

# The user and group are actually created by installing the bacula-common
# package which is pulled in when any other bacula package is installed.
# To work around the issue where every package resource is a separate run of
# yum we add requires for the packages we already have to the group resource.
  if $is_client {
    Group['bacula'] {
      require +> Package['bacula-client'],
    }
  } elsif $is_director {
    Group['bacula'] {
      require +> Package[$bacula::director::db_package],
    }
  } elsif $is_storage {
    Group['bacula'] {
      require +> Package[$bacula::storage::db_package],
    }
  } elsif $manage_console {
    Group['bacula'] {
      require +> Package[$bacula::params::console_package],
    }
  } elsif $manage_bat {
    Group['bacula'] {
      require +> Package[$bacula::params::bat_console_package],
    }
  }

  $db_parameters = $db_backend ? {
    'mysql'   => "--host=${db_host} --user=${db_user} --password=${db_password} --port=${db_port} --database=${db_database}",
    default   => '',
  }

  if $manage_db_tables {
    $make_db_tables_command = $::operatingsystem ? {
      /(Ubuntu|Debian)/ => '/usr/lib/bacula/make_bacula_tables',
      default           => '/usr/libexec/bacula/make_mysql_tables',
    }

    exec { 'make_db_tables':
      command     => "${make_db_tables_command} ${db_parameters}",
      refreshonly => true,
      require     => Package[$bacula::director::db_package],
    }
  }

  if $manage_db_tables   {
    case $db_backend {
      'mysql': {
        $db_notify = $manage_db_tables ? {
          true    => Exec['make_db_tables'],
          default => undef,
        }
        $db_require = defined(Class['mysql::server']) ? {
          true    => Class['mysql::server'],
          default => undef,
        }
        mysql::db { $db_database:
          user      => $db_user,
          password  => $db_password,
          host      => $db_host,
          notify    => $db_notify,
          require   => $db_require,
        }
      }

      'sqlite': {
        sqlite::db { $db_database:
          ensure   => present,
          location => "/var/lib/bacula/${db_database}.db",
          owner    => 'bacula',
          group    => 'bacula',
          require  => File['/var/lib/bacula'],
        }
      }

      default: {
        fail "The bacula module does not support managing the ${db_backend} backend database"
      }
    }
  }

  file { '/var/lib/bacula':
    ensure => directory,
    owner  => 'bacula',
    group  => 'bacula',
  }

  file { '/var/spool/bacula':
    ensure => directory,
    owner  => 'bacula',
    group  => 'bacula',
  }

  file { '/var/log/bacula':
    ensure  => directory,
    owner   => 'bacula',
    group   => 'bacula',
    recurse => true,
  }

  file { '/var/run/bacula':
    ensure => directory,
    owner  => 'bacula',
    group  => 'bacula',
  }
}
