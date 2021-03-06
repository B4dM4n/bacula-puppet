# == Define: bacula::client::config
#
# Install a config file describing a <code>bacula-fd</code> client on the director.
#
# === Parameters
#
# [*client_schedule*]
#   The schedule for backups to be performed.
# [*db_backend*]
#   The database backend of the catalog storing information about the backup
# [*director_password*]
#   The director's password the client is connecting to.
# [*director_server*]
#   The FQDN of the director server the client will connect to.
# [*fileset*]
#   The file set used by the client for backups
# [*pool*]
#   The pool used by the client for backups
# [*pool_diff*]
#   The pool to use for differential backups. Setting this to <code>false</code> will prevent configuring a specific pool for
#   differential backups. Defaults to <code>"${pool}.differential"</code>.
# [*pool_full*]
#   The pool to use for full backups. Setting this to <code>false</code> will prevent configuring a specific pool for full backups.
#   Defaults to <code>"${pool}.full"</code>.
# [*pool_incr*]
#   The pool to use for incremental backups. Setting this to <code>false</code> will prevent configuring a specific pool for
#   incremental backups. Defaults to <code>"${pool}.incremental"</code>.
# [*rerun_failed_levels*]
#   If this directive is set to <code>'yes'</code> (default <code>'no'</code>), and Bacula detects that a previous job at a higher
#   level (i.e. Full or Differential) has failed, the current job level will be upgraded to the higher level. This is particularly
#   useful for Laptops where they may often be unreachable, and if a prior Full save has failed, you wish the very next backup to be
#   a Full save rather than whatever level it is started as. There are several points that must be taken into account when using
#   this directive: first, a failed job is defined as one that has not terminated normally, which includes any running job of the
#   same name (you need to ensure that two jobs of the same name do not run simultaneously); secondly, the Ignore FileSet Changes
#   directive is not considered when checking for failed levels, which means that any FileSet change will trigger a rerun.
# [*restore_where*]
#   The default path to restore files to defined in the restore job for this client.
# [*run_scripts*]
#   An array of hashes containing the parameters for any
#   {RunScripts}[http://www.bacula.org/5.0.x-manuals/en/main/main/Configuring_Director.html#6971] to include in the backup job
#   definition. For each hash in the array a <code>RunScript</code> directive block will be inserted with the <code>key = value</code>
#   settings from the hash.  Note: The <code>RunsWhen</code> key is required.
# [*storage_server*]
#   The storage server hosting the pool this client will backup to
# [*tls_ca_cert*]
#   The full path and filename specifying a PEM encoded TLS CA certificate(s). Multiple certificates are permitted in
#   the file. One of <code>TLS CA Certificate File</code> or <code>TLS CA Certificate Dir</code> are required in a server context if
#   <code>TLS Verify Peer</code> is also specified, and are always required in a client context.
# [*tls_ca_cert_dir*]
#   Full path to TLS CA certificate directory. In the current implementation, certificates must be stored PEM
#   encoded with OpenSSL-compatible hashes, which is the subject name's hash and an extension of .0. One of
#   <code>TLS CA Certificate File</code> or <code>TLS CA Certificate Dir</code> are required in a server context if <code>TLS Verify Peer</code>
#   is also specified, and are always required in a client context.
# [*use_tls*]
#   Whether to use {Bacula TLS - Communications
#   Encryption}[http://www.bacula.org/en/dev-manual/main/main/Bacula_TLS_Communications.html].
#
# === Examples
#
#   bacula::client::config { 'client1.example.com' :
#     client_schedule   => 'WeeklyCycle',
#     db_backend        => 'mysql',
#     director_password => 'directorpassword',
#     director_server   => 'bacula.example.com',
#     fileset           => 'Basic:noHome',
#     pool              => 'otherpool',
#     storage_server    => 'bacula.example.com',
#   }
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
define bacula::client::config (
  $director_password   = '',
  $director_server     = undef,
  $tls_ca_cert         = undef,
  $tls_ca_cert_dir     = undef,
  $tls_require         = 'yes',
  $use_tls             = false,
  $db_backend          = undef,
  $default_job         = true,
  $client_schedule     = 'WeeklyCycle',
  $fileset             = 'Basic:noHome',
  $pool                = 'default',
  $pool_diff           = undef,
  $pool_full           = undef,
  $pool_incr           = undef,
  $rerun_failed_levels = 'no',
  $restore_where       = '/var/tmp/bacula-restores',
  $run_scripts         = undef,
  $storage_server      = undef,
) {
  include ::bacula::params

  if !is_domain_name($name) {
    fail "Name for client ${name} must be a fully qualified domain name"
  }

  case $db_backend {
    undef   : {
      $db_backend_real = $::bacula::director::db_backend ? {
        undef   => 'sqlite',
        default => $::bacula::director::db_backend,
      }
    }
    default : {
      $db_backend_real = $db_backend
    }
  }

  case $director_password {
    ''      : {
      $director_password_real = $::bacula::director::director_password ? {
        undef   => '',
        default => $::bacula::director::director_password,
      }
    }
    default : {
      $director_password_real = $director_password
    }
  }

  case $director_server {
    undef   : {
      $director_server_real = $::bacula::director::director_server ? {
        undef   => $::bacula::params::director_server_default,
        default => $::bacula::director::director_server,
      }
    }
    default : {
      $director_server_real = $director_server
    }
  }

  if !is_domain_name($director_server_real) {
    fail "director_server=${director_server_real} must be a fully qualified domain name"
  }

  if $default_job {
    bacula::client::job { "${name}:Default":
      schedule            => $client_schedule,
      director_server     => $director_server_real,
      fileset             => $fileset,
      pool                => $pool,
      pool_diff           => $pool_diff,
      pool_full           => $pool_full,
      pool_incr           => $pool_incr,
      rerun_failed_levels => $rerun_failed_levels,
      restore_where       => $restore_where,
      run_scripts         => $run_scripts,
      storage_server      => $storage_server,
    }  
  }

  file { "/etc/bacula/bacula-dir.d/${name}.conf":
    ensure  => file,
    owner   => 'bacula',
    group   => 'bacula',
    mode    => '0640',
    content => template('bacula/client_config.erb'),
    before  => Service['bacula-dir'],
    notify  => Exec['bacula-dir reload'],
  }
}
