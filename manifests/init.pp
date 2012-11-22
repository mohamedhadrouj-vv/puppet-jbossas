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
  $enable_service = true,
  $user = 'jboss',
  $group = 'jboss',
  $download_dir = '/tmp/jboss',
  $jboss_home = '/home/jboss',
  $jboss_dirname = 'jboss',
  $jboss_profile_name = 'production',
  $base_dynamic_class_resource_loading_port = 8083,
  $base_bootstrap_jnp_port = 1099,
  $base_rmi_port = 1098,
  $base_rmi_jrmp_invoker_port = 4444,
  $base_pooled_invoker_port = 4445,
  $base_jboss_remoting_connector_port = 4446,
  $base_web_container_http_port = 8080,
  $base_web_container_https_port = 8443,
  $base_web_container_ajp_port = 8009,
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
        '4' => 'jbossas/jboss4/init.d/jboss-as.init.erb',
        '5' => 'jbossas/jboss5/init.d/jboss-as-standalone.init.erb',
        '6' => 'jbossas/jboss6/init.d/jboss-as-standalone.init.erb',
        '7' => 'jbossas/jboss7/init.d/jboss-as-standalone.init.erb',
        default => 'jbossas/jboss4/init.d/jboss-as.init.erb',
    }

    $init_script_conf = $jbossas::version ? {
        '4' => 'jbossas/jboss4/etc/jboss-as.conf.erb',
        '5' => 'jbossas/jboss5/etc/jboss-as.conf.erb',
        '6' => 'jbossas/jboss6/etc/jboss-as.conf.erb',
        '7' => 'jbossas/jboss7/etc/jboss-as.conf.erb',
     	default => 'jbossas/jboss4/etc/jboss-as.conf.erb',
    }

    $dist_file = "${jbossas::download_dir}/jboss-as-${jbossas::version}.zip"

    notice "Download URL: ${mirror_url_version}"
    notice "JBoss AS directory: ${jbossas::jboss_home}/${jbossas::jboss_dirname}"

    # Create user, and home folder
    file { "${jbossas::jboss_home}":
      ensure  => present,
      owner   => $jbossas::user,
      group   => $jbossas::group,
      mode    => 0775,
    }

    # Download the JBoss AS distribution ~100MB file
    file { "${jbossas::download_dir}":
      ensure  => directory,
      owner   => $jbossas::user,
      group   => $jbossas::group,
      mode    => 0775,
    }
    exec { "download_jboss_${jbossas::user}":
      command   => "/usr/bin/curl --progress-bar -o ${dist_file} ${mirror_url_version} -L",
      creates   => $dist_file,
      user      => $jbossas::user,
      logoutput => true,
      unless    => "/usr/bin/test -d ${dist_file}",
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
      require   => [ Exec["download_jboss_${jbossas::user}"] ]
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
      require => [ Exec["move_jboss_home_${jbossas::user}"] ]
    }

  }

  # init.d configuration for Ubuntu
  class initd {
    $jbossas_bind_address = $jbossas::bind_address
    $jbossas_user	  = $jbossas::user
    $jbossas_home 	  = $jbossas::jboss_home
    $jbossas_dirname 	  = $jbossas::jboss_dirname
    $jbossas_profile_name = $jbossas::jboss_profile_name	

#TODO
$bootstrap_jnp_service_port = 1099

    file { "/etc/jboss-${jbossas::user}":
      ensure => directory,
      owner  => 'root',
      group  => 'root',
    }
    file { "/etc/jboss-${jbossas::user}/jboss-as.conf":
      content => template($install::init_script_conf),
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
      mode   => 0775,
    }
    file { "/etc/init.d/jboss-${jbossas::user}":
      content => template($install::init_script),
      owner   => 'root',
      group   => 'root',
      mode    => 0755,
    }
  }
  
  class profile {
    # Configure
    notice "Bind address: ${bind_address} - HTTP Port: ${http_port} - HTTPS Port: ${https_port}"
    case $jbossas::version {
       '4': { include profile::jboss4 }
       '5': { include profile::jboss5 }
       '6': { include profile::jboss6 }
       '7': { include profile::jboss7 }
       default: { include profile::jboss4 }
    }
  }

  class profile::jboss4 {
      notice "Creating new JBoss custom profile..."
      file{"${jbossas::jboss_home}/${jbossas::jboss_dirname}/server/${jbossas::jboss_profile_name}":
	ensure 	=> directory,
	owner  	=> $jbossas::user,
	group  	=> $jbossas::group,
      }
      file{"${jbossas::jboss_home}/${jbossas::jboss_dirname}/server/${jbossas::jboss_profile_name}/deploy":
        ensure  => directory,
        owner   => $jbossas::user,
        group   => $jbossas::group,
      }

      notice "-Copying conf, lib directories from default profile..."
      exec { "copy_lib_dir_${jbossas::user}":
        command         => "/bin/cp -R default/lib ${jbossas::jboss_profile_name}",
        user            => $jbossas::user,
        cwd             => "${jbossas::jboss_home}/${jbossas::jboss_dirname}/server",
        logoutput       => true,
        require         => file["${jbossas::jboss_home}/${jbossas::jboss_dirname}/server/${jbossas::jboss_profile_name}"],
        unless          => "/usr/bin/test -d ${jbossas::jboss_profile_name}/lib",
      }
      exec { "copy_conf_dir_${jbossas::user}":
	command		=> "/bin/cp -R default/conf ${jbossas::jboss_profile_name}",
	user		=> $jbossas::user,
	cwd		=> "${jbossas::jboss_home}/${jbossas::jboss_dirname}/server",
	logoutput	=> true,
	require		=> file["${jbossas::jboss_home}/${jbossas::jboss_dirname}/server/${jbossas::jboss_profile_name}"],
	unless		=> "/usr/bin/test -d ${jbossas::jboss_profile_name}/conf",
      }

      notice "-Copying deploy files from default profile..."
      exec { "copy_deploy_dir_${jbossas::user}":
        command         => "/bin/cp -R default/deploy/jboss-web.deployer ${jbossas::jboss_profile_name}/deploy/",
        user            => $jbossas::user,
        cwd             => "${jbossas::jboss_home}/${jbossas::jboss_dirname}/server",
        logoutput       => true,
        require         => file["${jbossas::jboss_home}/${jbossas::jboss_dirname}/server/${jbossas::jboss_profile_name}"],
        unless          => "/usr/bin/test -d ${jbossas::jboss_profile_name}/deploy/jboss-web.deployer",
      }
      exec { "copy_deploy_files_${jbossas::user}":
        command         => "/bin/cp default/deploy/jbossjca-service.xml default/deploy/jboss-local-jdbc.rar default/deploy/jboss-xa-jdbc.rar default/deploy/jmx-invoker-service.xml default/deploy/sqlexception-service.xml ${jbossas::jboss_profile_name}/deploy",
        user            => $jbossas::user,
        cwd             => "${jbossas::jboss_home}/${jbossas::jboss_dirname}/server",
        logoutput       => true,
        require         => file["${jbossas::jboss_home}/${jbossas::jboss_dirname}/server/${jbossas::jboss_profile_name}"],
        unless          => "/usr/bin/test -f ${jbossas::jboss_profile_name}/deploy/jbossjca-service.xml",
      }

      notice "-Replacing vars in templates..."
      #TODO : A supprimer
      $env = 0
      if $jbossas::user =~ /^env(\d+)\./ {
        $env = $1 + 0
      }
      #TODO : A supprimer

      $dynamic_class_resource_loading_port = $jbossas::base_dynamic_class_resource_loading_port + $env
      $bootstrap_jnp_port = $jbossas::base_bootstrap_jnp_port + $env
      $rmi_port = $jbossas::base_rmi_port + $env
      $rmi_jrmp_invoker_port = $jbossas::base_rmi_jrmp_invoker_port + $env
      $pooled_invoker_port = $jbossas::base_pooled_invoker_port + $env
      $jboss_remoting_connector_port = $jbossas::base_jboss_remoting_connector_port + $env
      $web_container_http_port = $jbossas::base_web_container_http_port + $env
      $web_container_https_port = $jbossas::base_web_container_https_port + $env
      $web_container_ajp_port = $jbossas::base_web_container_ajp_port + $env

      file { "${jbossas::jboss_home}/${jbossas::jboss_dirname}/server/${jbossas::jboss_profile_name}/conf/jboss_service.xml":
      	content => template('jbossas/jboss4/conf/jboss-service.xml.erb'),
      	owner   => $jbossas::user,
      	group   => $jbossas::group,
      	mode    => 0644,
	notify    => Service["jboss-${jbossas::user}"],
      }
      file { "${jbossas::jboss_home}/${jbossas::jboss_dirname}/server/${jbossas::jboss_profile_name}/deploy/jboss-web.deployer/server.xml":
        content => template('jbossas/jboss4/deploy/jboss-web.deployer/server.xml.erb'),
        owner   => $jbossas::user,
        group   => $jbossas::group,
        mode    => 0644,
	notify    => Service["jboss-${jbossas::user}"],
      }
  }

  class profile::jboss7 {
    #TODO Replace Sed commands with erb templates
    exec { "jboss-${jbossas::user}_http_port":
      command   => "/bin/sed -i -e 's/socket-binding name=\"http\" port=\"[0-9]\\+\"/socket-binding name=\"http\" port=\"${jbossas::http_port}\"/' standalone/configuration/standalone.xml",
      user      => $jbossas::user,
      cwd       => "${jbossas::jboss_home}/${jbossas::jboss_dirname}",
      logoutput => true,
      require   => Class['jbossas::install'],
      unless    => "/bin/grep 'socket-binding name=\"http\" port=\"${jbossas::http_port}\"/' standalone/configuration/standalone.xml",
      notify    => Service["jboss-${jbossas::user}"],
    }

    exec { "jboss-${jbossas::user}_https_port":
      command   => "/bin/sed -i -e 's/socket-binding name=\"https\" port=\"[0-9]\\+\"/socket-binding name=\"https\" port=\"${jbossas::https_port}\"/' standalone/configuration/standalone.xml",
      user      => $jbossas::user,
      cwd       => "${jbossas::jboss_home}/${jbossas::jboss_dirname}",
      logoutput => true,
      require   => Class['jbossas::install'],
      unless    => "/bin/grep 'socket-binding name=\"https\" port=\"${jbossas::https_port}\"/' standalone/configuration/standalone.xml",
      notify    => Service["jboss-${jbossas::user}"]
    }
  }

  Class['install'] -> Class['initd'] -> Class['profile']

  include install
  include initd
  include profile

  service { "jboss-${jbossas::user}":
    enable => $enable_service,
    ensure => $enable_service ? { true => running, default => undef },
    require => [ Class['jbossas::initd'],  Class['jbossas::profile'] ],
  }

}
