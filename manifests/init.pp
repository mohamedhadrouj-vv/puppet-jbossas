# Class: jbossas
#
# This module manages JBoss Application Server 7.x
#
# Parameters:
# * @version@ = '7.1.1.Final'
# * @mirror_url@ = 'http://download.jboss.org/jbossas/7.1/jboss-as-7.1.1.Final/'
# * @bind_address@ = '127.0.0.1'
# * @http_port@ = 8080
# * @https_port@ = 8443
#
# Actions:
#
# Requires:
# * package wget
#
# Sample Usage:
#
# [Remember: No empty lines between comments and class definition]
class jbossas (
  $version = '7',
  # Mirror URL with trailing slash
  # Will use wget to download, so 'file:///' is also possible not just 'http://'
  $mirror_url = 'http://download.jboss.org/jbossas/7.1/jboss-as-7.1.1.Final/jboss-as-7.1.1.Final.zip',
  $bind_address = '127.0.0.1',
  $http_port = 8080,
  $https_port = 8443,
  $enable_service = true,
  $user = 'jboss',
  $group = 'jboss',
  $download_dir = '/tmp/jboss',
  $jboss_home = '/home/jboss',
  $jboss_dirname = 'jboss'
)
{

  class install {
    $mirror_url_version='http://download.jboss.org/jbossas/7.1/jboss-as-7.1.1.Final/jboss-as-7.1.1.Final.zip'
    $unzipped_dirname='jboss-as-7.1.1.Final'
    case $version {
      '4' : { $mirror_url_version='http://sourceforge.net/projects/jboss/files/JBoss/JBoss-4.2.3.GA/jboss-4.2.3.GA.zip/download'
	     $unzipped_dirname='jboss-4.2.3.GA'
	}
      '5' : { $mirror_url_version='http://sourceforge.net/projects/jboss/files/JBoss/JBoss-5.1.0.GA/jboss-5.1.0.GA.zip/download' }
      '6' : { $mirror_url_version='http://download.jboss.org/jbossas/6.1/jboss-as-distribution-6.1.0.Final.zip' }
      '7' : { $mirror_url_version='http://download.jboss.org/jbossas/7.1/jboss-as-7.1.1.Final/jboss-as-7.1.1.Final.zip' }
    }	
    $dist_file = "${jbossas::download_dir}/jboss-as-${jbossas::version}.zip"

    notice "Download URL: ${mirror_url_version}"
    notice "JBoss AS directory: ${jbossas::jboss_home}/${jbossas::jboss_dirname}"

    # Create group, user, and home folder
    #group { "${jbossas::group}":
    #  ensure => present
    #}
    user { "${jbossas::user}":
      ensure     => present,
      managehome => true,
      comment    => 'JBoss Application Server User'
    }
    file { "${jbossas::jboss_home}":
      ensure  => present,
      owner   => $jbossas::user,
      group   => $jbossas::group,
      mode    => 0775,
      require => [ User[$jbossas::user] ]
    }

    # Download the JBoss AS distribution ~100MB file
    file { "${jbossas::download_dir}":
      ensure  => directory,
      owner   => $jbossas::user,
      group   => $jbossas::group,
      mode    => 0775,
      require => [ User[$jbossas::user] ]
    }
    exec { download_jboss_as:
      command   => "/usr/bin/curl -o ${dist_file} ${mirror_url_version}",
      creates   => $dist_file,
      user      => $jbossas::user,
      logoutput => true,
      require   => [ Package['curl'], File["${jbossas::download_dir}"] ],
    }

    # Extract the JBoss AS distribution
    exec { extract_jboss_as:
      command   => "/usr/bin/unzip -o '${dist_file}' -d ${jbossas::jboss_home}",
      creates   => "${jbossas::jboss_home}/jboss-as-${jbossas::version}",
      cwd       => $jbossas::jboss_home,
      user      => $jbossas::user,
      group     => $jbossas::group,
      logoutput => true,
      unless    => "/usr/bin/test -d ${jbossas::jboss_home}/jboss-as-${jbossas::version}",
      require   => [ User[$jbossas::user], Exec['download_jboss_as'] ]
    }

# TODO: unzipping to a named dir instead of unzip + renaming

    exec { move_jboss_home:
      command   => "/bin/mv -v '${jbossas::jboss_home}/${unzipped_dirname}' '${jbossas::jboss_home}/${jbossas::jboss_dirname}'",
      creates   => "${jbossas::jboss_home}/${jbossas::jboss_dirname}",
      logoutput => true,
      require   => Exec['extract_jboss_as']
    }
    #change owner of the jboss home dir
    file { "${jbossas::jboss_home}/${jbossas::jboss_dirname}":
      ensure  => directory,
      owner   => $jbossas::user,
      group   => $jbossas::group,
      require => [ User[$jbossas::user], Exec['move_jboss_home'] ]
    }

  }

  # init.d configuration for Ubuntu
  class initd {
    $jbossas_bind_address = $jbossas::bind_address
    $jbossas_user	  = $jbossas::user

    file { '/etc/jboss-as':
      ensure => directory,
      owner  => 'root',
      group  => 'root'
    }
    file { '/etc/jboss-as/jboss-as.conf':
      content => template('jbossas/jboss-as.conf.erb'),
      owner   => 'root',
      group   => 'root',
      mode    => 0644,
      require => File['/etc/jboss-as'],
      notify  => Service['jboss-as'],
    }
    file { '/var/run/jboss-as':
      ensure => directory,
      owner  => $jbossas::user,
      group  => $jbossas::group,
      mode   => 0775
    }
    file { '/etc/init.d/jboss-as':
      source  => 'puppet:///modules/jbossas/jboss-as-standalone.sh',
      owner   => 'root',
      group   => 'root',
      mode    => 0755,
    }
  }
  Class['install'] -> Class['initd']

  include install
  include initd

  # Configure
  notice "Bind address: ${bind_address} - HTTP Port: ${http_port} - HTTPS Port: ${https_port}"
  exec { jbossas_http_port:
  	command   => "/bin/sed -i -e 's/socket-binding name=\"http\" port=\"[0-9]\\+\"/socket-binding name=\"http\" port=\"${http_port}\"/' standalone/configuration/standalone.xml",
    user      => $jbossas::user,
    cwd       => "${jbossas::jboss_home}/${jbossas::jboss_dirname}",
    logoutput => true,
    require   => Class['jbossas::install'],
    unless    => "/bin/grep 'socket-binding name=\"http\" port=\"${http_port}\"/' standalone/configuration/standalone.xml",
    notify    => Service['jboss-as'],
  }
  exec { jbossas_https_port:
    command   => "/bin/sed -i -e 's/socket-binding name=\"https\" port=\"[0-9]\\+\"/socket-binding name=\"https\" port=\"${https_port}\"/' standalone/configuration/standalone.xml",
    user      => $jbossas::user,
    cwd       => "${jboss_home}/${jbossas::jboss_dirname}",
    logoutput => true,
    require   => Class['jbossas::install'],
    unless    => "/bin/grep 'socket-binding name=\"https\" port=\"${https_port}\"/' standalone/configuration/standalone.xml",
    notify    => Service['jboss-as']
  }

  service { jboss-as:
    enable => $enable_service,
    ensure => $enable_service ? { true => running, default => undef },
    require => [ Class['jbossas::initd'], Exec['jbossas_http_port', 'jbossas_https_port']
                  ]
  }

  define virtual_server($default_web_module = '',
    $aliases = [],
    $ensure = 'present')
  {
    case $ensure {
      'present': {
#        notice "JBoss Virtual Server $name: default_web_module=$default_web_module"
        if $default_web_module {
          $cli_args = inline_template('<% require "json" %>default-web-module=<%= default_web_module %>,alias=<%= aliases.to_json.gsub("\"", "\\\"") %>')
        } else {
          $cli_args = inline_template("<% require 'json' %>alias=<%= aliases.to_json %>")
        }
        notice "${jboss_home}/${jbossas::jboss_dirname}/bin/jboss-cli.sh -c --command='/subsystem=web/virtual-server=$name:add\\($cli_args\\)'"
        exec { "add jboss virtual-server $name":
          command => "${jbossas::jboss_home}/${jbossas::jboss_dirname}/bin/jboss-cli.sh -c --command=/subsystem=web/virtual-server=$name:add\\($cli_args\\)",
          user => $jbossas::user, 
	  group => $jbossas::group,
          logoutput => true,
          unless => "/bin/sh ${jbossas::jboss_home}/${jbossas::jboss_dirname}/bin/jboss-cli.sh -c /subsystem=web/virtual-server=$name:read-resource | grep success",
          notify => Service['jboss-as'],
          provider => 'posix'
        }
      }
      'absent': {
        exec { "remove jboss virtual-server $name":
          command => "${jbossas::jboss_home}/${jbossas::jboss_dirname}/bin/jboss-cli.sh -c '/subsystem=web/virtual-server=$name:remove()'",
          user => $jbossas::user,
	  group => $jbossas::group,
          logoutput => true,
          onlyif => "/bin/sh ${jbossas::jboss_home}/${jbossas::jboss_dirname}/bin/jboss-cli.sh -c /subsystem=web/virtual-server=$name:read-resource | grep success",
          notify => Service['jboss-as'],
          provider => 'posix'
        }
      }
    }
  }

}
