# == Class: bacula::director::mysql
#
# Manage postgresql resources for the Bacula director.
#
# === Parameters
#
# All <tt>bacula+ classes are called from the main <tt>::bacula</tt> class.  Parameters
# are documented there.
#
# === Copyright
#
# Copyright 2012 Russell Harrison
#
# === License
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
class bacula::director::postgresql (
  $db_database  = 'bacula',
  $db_password  = '',
  $db_user      = '',
  $manage_db    = false
){
  include ::bacula::params

  if $manage_db {
    class { 'postgresql::server': 
    } ->
    postgresql::db { $db_database:
      user     => $db_user,
      password => $db_password
#      before  => Package[$::bacula::params::director_postgresql_package]
    } -> Package[$::bacula::params::director_postgresql_package]

    $db_host = ''
    $db_port = ''

    file { '/etc/dbconfig-common/bacula-director-pgsql.conf':
      ensure  => file,
      owner   => 'root',
      group   => 'root',
      mode    => '0600',
      content => template('bacula/bacula-director-pgsql.conf.erb'),
      before  => Package[$::bacula::params::director_postgresql_package]
    }

    exec { 'make_db_tables':
      command     => "/bin/true",
      refreshonly => true,
    }
  }
}
