# == Define: bacula::director::fileset
#
# Configure an additional basic file set to be used by the Bacula clients. See the {FileSet
# Resource}[http://www.bacula.org/5.0.x-manuals/en/main/main/Configuring_Director.html#SECTION001870000000000000000] documentation
# for information on the options.
#
# === Parameters
#
# [*ensure*]
#   Ensure the file is present or absent.  The only valid values are <tt>file</tt> or
#   <tt>absent+. Defaults to <tt>file</tt>.
# [*exclude_files*]
#   An array of strings consisting of one file or directory name per entry. Directory names should be specified without
#   a trailing slash with Unix path notation.
# [*include_files*]
#   *Required*: An array of strings consisting of one file or directory name per entry. Directory names should be specified without
#   a trailing slash with Unix path notation.
# [*copression*]
#   The compression level for backups. Value can be GZIP1 to GZIP9, GZIP which defaults to GZIP6 or LZO
#
# === Examples
#
#   $servicename_include_files = [
#     '/etc/servicename',
#     '/var/lib/servicename',
#     '/var/log/servicename',
#     '/var/spool/servicename',
#   ]
#   $servicename_exclude_files = [
#     '/var/lib/servicename/tmp'
#   ]
#
#   bacula::director::fileset { 'servicename' :
#     ensure         => file,
#     include_files => $servicename_include_files,
#     exclude_files => $servicename_exclude_files,
#   }
#
define bacula::director::fileset (
  $ensure   = 'file',
  $exclude_files = undef,
  $include_files = undef,
  $compression = 'GZIP'
) {

  if !($ensure in ['file', 'absent']) {
    fail('The only valid values for the ensure parameter are file or absent')
  }

  file { "/etc/bacula/bacula-dir.d/fileset-${name}.conf":
    ensure  => file,
    owner   => 'bacula',
    group   => 'bacula',
    mode    => '0640',
    content => template('bacula/fileset.conf.erb'),
    require => File['/etc/bacula/bacula-dir.conf'],
    before  => Service['bacula-dir'],
    notify  => Exec['bacula-dir reload'],
  }
}
