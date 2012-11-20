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
# * package curl
#
# Sample Usage:
#
# [Remember: No empty lines between comments and class definition]
class jbossas (
  $version = '4',
  # Mirror URL with trailing slash
  # Will use curl to download, so 'file:///' is also possible not just 'http://'
  $mirror_url = 'http://sourceforge.net/projects/jboss/files/JBoss/JBoss-4.2.3.GA/jboss-4.2.3.GA.zip/download',
  $bind_address = '127.0.0.1',
  $http_port = 8080,
  $https_port = 8443,
  $enable_service = true,
  $user = 'jboss',
  $group = 'jboss',
  $download_dir = '/tmp/jboss',
  $jboss_home = '/home/jboss',
  $jboss_dirname = 'jboss',
)
{

  class install {

    #if $jbossas::mirror_url == '' {
      $mirror_url_version = $jbossas::version ? {
      	'4' => 'http://sourceforge.net/projects/jboss/files/JBoss/JBoss-4.2.3.GA/jboss-4.2.3.GA.zip/download',
      	'5' => 'http://sourceforge.net/projects/jboss/files/JBoss/JBoss-5.1.0.GA/jboss-5.1.0.GA.zip/download',
      	'6' => 'http://download.jboss.org/jbossas/6.1/jboss-as-distribution-6.1.0.Final.zip',
      	'7' => 'http://download.jboss.org/jbossas/7.1/jboss-as-7.1.1.Final/jboss-as-7.1.1.Final.zip',
     	default => 'http://sourceforge.net/projects/jboss/files/JBoss/JBoss-4.2.3.GA/jboss-4.2.3.GA.zip/download',
      }
    #}

    $unzipped_dirname = $jbossas::version ? {
      	'4' => 'jboss-4.2.3.GA',
      	'5' => 'jboss-5.1.0.GA',
      	'6' => 'jboss-as-distribution-6.1.0.Final',
      	'7' => 'jboss-as-7.1.1.Final',
     	default => 'jboss-4.2.3.GA',
    }


    $init_script = $jbossas::version ? {
        '4' => 'jbossas/init.d/jboss4-as-standalone.init.erb',
        '5' => 'jbossas/init.d/jboss5-as-standalone.init.erb',
        '6' => 'jbossas/init.d/jboss6-as-standalone.init.erb',
        '7' => 'jbossas/init.d/jboss7-as-standalone.init.erb',
     	default => 'jbossas/init.d/jboss4-as-standalone.init.erb',
    }

    $dist_file = "${jbossas::download_dir}/jboss-as-${jbossas::version}.zip"

    notice "Download URL: ${mirror_url_version}"
    notice "JBoss AS directory: ${jbossas::jboss_home}/${jbossas::jboss_dirname}"

    # Create user, and home folder
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
    exec { "download_jboss_${jbossas::user}":
      command   => "/usr/bin/curl -o ${dist_file} ${mirror_url_version} -L",
      creates   => $dist_file,
      user      => $jbossas::user,
      logoutput => true,
      unless    => "/usr/bin/test -d ${jbossas::jboss_home}/${jbossas::jboss_dirname}",
      require   => [ Package['curl'], File["${jbossas::download_dir}"] ],
    }

    # Extract the JBoss AS distribution
    exec { "extract_jboss_${jbossas::user}":
      command   => "/usr/bin/unzip -o '${dist_file}' -d ${jbossas::jboss_home}",
      creates   => "${jbossas::jboss_home}/jboss-as-${jbossas::version}",
      cwd       => $jbossas::jboss_home,
      user      => $jbossas::user,
      group     => $jbossas::group,
      logoutput => true,
      unless    => "/usr/bin/test -d ${jbossas::jboss_home}/${jbossas::jboss_dirname}",
      require   => [ User[$jbossas::user], Exec["download_jboss_${jbossas::user}"] ]
    }

# TODO: unzipping to a named dir instead of unzip + renaming

    exec { "move_jboss_home_${jbossas::user}":
      command   => "/bin/mv -v '${jbossas::jboss_home}/${unzipped_dirname}' '${jbossas::jboss_home}/${jbossas::jboss_dirname}'",
      creates   => "${jbossas::jboss_home}/${jbossas::jboss_dirname}",
      logoutput => true,
      unless    => "/usr/bin/test -d ${jbossas::jboss_home}/${jbossas::jboss_dirname}",
      require   => Exec["extract_jboss_${jbossas::user}"]
    }
    #change owner of the jboss home dir
    file { "${jbossas::jboss_home}/${jbossas::jboss_dirname}":
      ensure  => directory,
      owner   => $jbossas::user,
      group   => $jbossas::group,
      require => [ User[$jbossas::user], Exec["move_jboss_home_${jbossas::user}"] ]
    }

  }

  # init.d configuration for Ubuntu
  class initd {
    $jbossas_bind_address = $jbossas::bind_address
    $jbossas_user	  = $jbossas::user
    $jbossas_home 	  = $jbossas::jboss_home
    $jbossas_dirname 	  = $jbossas::jboss_dirname

    file { "/etc/jboss-${jbossas::user}":
      ensure => directory,
      owner  => 'root',
      group  => 'root'
    }
    file { "/etc/jboss-${jbossas::user}/jboss-as.conf":
      content => template('jbossas/jboss-as.conf.erb'),
      owner   => 'root',
      group   => 'root',
      mode    => 0644,
      require => File["/etc/jboss-${jbossas::user}"],
      notify  => Service["jboss-${jbossas::user}"],
    }
    file { "/var/run/jboss-${jbossas::user}":
      ensure => directory,
      owner  => $jbossas::user,
      group  => $jbossas::group,
      mode   => 0775
    }
    file { "/etc/init.d/jboss-${jbossas::user}":
      content => template($install::init_script),
      owner   => 'root',
      group   => 'root',
      mode    => 0755
    }
  }
  Class['install'] -> Class['initd']

  include install
  include initd

  # Configure
  notice "Bind address: ${bind_address} - HTTP Port: ${http_port} - HTTPS Port: ${https_port}"
  
  exec { "jboss-${jbossas::user}_http_port":
  	command   => "/bin/sed -i -e 's/socket-binding name=\"http\" port=\"[0-9]\\+\"/socket-binding name=\"http\" port=\"${http_port}\"/' standalone/configuration/standalone.xml",
    user      => $jbossas::user,
    cwd       => "${jbossas::jboss_home}/${jbossas::jboss_dirname}",
    logoutput => true,
    require   => Class['jbossas::install'],
    unless    => "/bin/grep 'socket-binding name=\"http\" port=\"${http_port}\"/' standalone/configuration/standalone.xml",
    notify    => Service["jboss-${jbossas::user}"],
  }
  exec { "jboss-${jbossas::user}_https_port":
    command   => "/bin/sed -i -e 's/socket-binding name=\"https\" port=\"[0-9]\\+\"/socket-binding name=\"https\" port=\"${https_port}\"/' standalone/configuration/standalone.xml",
    user      => $jbossas::user,
    cwd       => "${jboss_home}/${jbossas::jboss_dirname}",
    logoutput => true,
    require   => Class['jbossas::install'],
    unless    => "/bin/grep 'socket-binding name=\"https\" port=\"${https_port}\"/' standalone/configuration/standalone.xml",
    notify    => Service["jboss-${jbossas::user}"]
  }

  service { "jboss-${jbossas::user}":
    enable => $enable_service,
    ensure => $enable_service ? { true => running, default => undef },
    require => [ Class['jbossas::initd'], Exec["jboss-${jbossas::user}_http_port", "jboss-${jbossas::user}_https_port"] ]
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
          notify => Service["jboss-${jbossas::user}"],
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
          notify => Service["jboss-${jbossas::user}"],
          provider => 'posix'
        }
      }
    }
  }

}
