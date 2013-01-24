# Define: jbossas
#
# This module manages JBoss Application Server 4
# Versions 5,6 and 7 are to be implemented
#
# Parameters:
#
# Actions:
#
# Requires:
# * package curl
#
# Sample Usage:
#
# [Remember: No empty lines between comments and class definition]
define jbossas::server (
  $version = '4',
  # Mirror URL with trailing slash
  # Will use curl to download, so 'file:///' is also possible not just 'http://'
  $mirror_url = 'http://freefr.dl.sourceforge.net/project/jboss/JBoss/JBoss-4.2.3.GA/jboss-4.2.3.GA-jdk6.zip',
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
  $jvm_xms =128,
  $jvm_xmx = 512,
  $jvm_maxpermsize = 256,
  $java_opts = {},
){

    #Download and install Jboss
    jbossas::install { "${name}":
       mirror_url       => $mirror_url,
       version          => $version,
       download_dir     => $download_dir,
       jboss_home       => $jboss_home,
       jboss_dirname    => $jboss_dirname,
       user             => $user,
       group            => $group,
       jvm_xms          => $jvm_xms,
       jvm_xmx          => $jvm_xmx,
       jvm_maxpermsize  => $jvm_maxpermsize,
       java_opts        => $java_opts,
    }

    #Installs JBoss service
    jbossas::initd { "${name}":
      bind_address => $bind_address,
      user => $user,
      group => $group,
      jboss_home => $jboss_home,
      jboss_dirname => $jboss_dirname,
      jboss_profile_name => $jboss_profile_name,
      version => $version,
      bootstrap_jnp_service_port => $base_bootstrap_jnp_port,
      require => Jbossas::Install[$name],
    }

    #Create a custom JBoss profile
    jbossas::profile { "${name}":
      jboss_home => $jboss_home,
      jboss_dirname => $jboss_dirname,
      jboss_profile_name => $jboss_profile_name,
      base_bootstrap_jnp_port => $base_bootstrap_jnp_port,
      user => $user,
      group => $group,
      require => Jbossas::Initd[$name],
    }

    #Cleanup JBoss from Jaxb
    file {["${jboss_home}/${jboss_dirname}/lib/jaxb-api.jar",
          "${jboss_home}/${jboss_dirname}/lib/jaxb-impl.jar",
          "${jboss_home}/${jboss_dirname}/lib/endorsed/jaxb-api.jar"] :
       ensure   => absent,
       require  => Jbossas::Profile["${name}"]
    }

    #Create JBoss service + set it to run on boot
    service { "jboss-${name}":
      enable    => $enable_service,
      ensure    => $enable_service ? { true => running, default => undef },
      hasstatus => false,
      status    => "ps aux | grep ${jboss_home}/${jboss_dirname}/bin/run.sh | grep -v grep",
      require   => Jbossas::Profile[$name],
      #subscribe => File["${jboss_home}/${jboss_dirname}/server/${jboss_profile_name}/deploy/jboss-web.deployer/server.xml",
      #                  "${jboss_home}/${jboss_dirname}/server/${jboss_profile_name}/deploy/jboss-web.deployer/META-INF/jboss-service.xml"],
    }

}

define jbossas::install (
    $mirror_url = 'http://freefr.dl.sourceforge.net/project/jboss/JBoss/JBoss-4.2.3.GA/jboss-4.2.3.GA-jdk6.zip',
    $version = '4',
    $download_dir = '/tmp/jboss',
    $jboss_home = '/home/jboss',
    $user = 'jboss',
    $group = 'jboss',
    $jboss_dirname = 'jboss',
    $jvm_xms = '',
    $jvm_xmx = '',
    $jvm_maxpermsize = '',
    $java_opts = {},
) {

  #if $mirror_url == '' {
    $mirror_url_version = $version ? {
      '4' => 'http://freefr.dl.sourceforge.net/project/jboss/JBoss/JBoss-4.2.3.GA/jboss-4.2.3.GA-jdk6.zip',
      '5' => 'http://sourceforge.net/projects/jboss/files/JBoss/JBoss-5.1.0.GA/jboss-5.1.0.GA.zip/download',
      '6' => 'http://download.jboss.org/jbossas/6.1/jboss-as-distribution-6.1.0.Final.zip',
      '7' => 'http://download.jboss.org/jbossas/7.1/jboss-as-7.1.1.Final/jboss-as-7.1.1.Final.zip',
      default => 'http://sourceforge.net/projects/jboss/files/JBoss/JBoss-4.2.3.GA/jboss-4.2.3.GA.zip/download',
    }
  #}

  $unzipped_dirname = $version ? {
      '4' => 'jboss-4.2.3.GA',
      '5' => 'jboss-5.1.0.GA',
      '6' => 'jboss-as-distribution-6.1.0.Final',
      '7' => 'jboss-as-7.1.1.Final',
      default => 'jboss-4.2.3.GA',
  }

  $zipfile_checksum = $version ? {
      '4' => 'a39e85981958fea2411e9346e218aa39',
      '5' => '78322c75ca0c13002a04418b4a8bc920',
      '6' => '2264e4d5ba448fa07716008d1452f1e7',
      '7' => '175c92545454f4e7270821f4b8326c4e',
      default => 'a39e85981958fea2411e9346e218aa39',
  }


  $dist_file = "${download_dir}/${name}/jboss-as-${version}.zip"

  notice "Download URL: ${mirror_url_version}"
  notice "JBoss AS directory: ${jboss_home}/${jboss_dirname}"

  # Create home folder
  file { "${jboss_home}":
    ensure  => present,
    owner   => $user,
    group   => $group,
    mode    => 0775,
  }

  file { "${download_dir}/${name}":
    ensure  => directory,
    owner   => $user,
    group   => $group,
    mode    => 0775,
    require => File[$jboss_home],
  }

  #create md5sum file to check downloaded zip
  file { "${dist_file}.md5sum":
    content => "${zipfile_checksum}  ${dist_file}",
    owner   => $user,
    group   => $group,
    mode    => 0775,
    require => File["${download_dir}/${name}"],
  }

  # Download the JBoss AS distribution ~100MB file
  exec { "download_jboss_${user}":
    command   => "/usr/bin/curl --progress-bar -o ${dist_file} ${mirror_url_version} -L",
    creates   => $dist_file,
    user      => $user,
    logoutput => true,
    timeout   => 0,
    unless    => "/usr/bin/md5sum --check ${dist_file}.md5sum",
    require   => [ Package['curl'], File["${download_dir}/${name}"],  File["${dist_file}.md5sum"] ],
  }

  # Extract the JBoss AS distribution
  exec { "extract_jboss_${user}":
    command   => "/usr/bin/unzip -q -o '${dist_file}' -d ${jboss_home}",
    creates   => "${jboss_home}/jboss-as-${version}",
    cwd       => $jboss_home,
    user      => $user,
    group     => $group,
    logoutput => 'on_failure',
    unless    => "/usr/bin/test -d ${jboss_home}/${jboss_dirname}",
    require   => [ Exec["download_jboss_${user}"] ]
  }

# TODO: unzipping to a named dir instead of unzip + renaming

  exec { "move_jboss_home_${user}":
    command   => "/bin/mv -v '${jboss_home}/${unzipped_dirname}' '${jboss_home}/${jboss_dirname}'",
    creates   => "${jboss_home}/${jboss_dirname}",
    logoutput => 'on_failure',
    unless    => "/usr/bin/test -d ${jboss_home}/${jboss_dirname}",
    require   => Exec["extract_jboss_${user}"]
  }
  #change owner of the jboss home dir
  file { "${jboss_home}/${jboss_dirname}":
    ensure  => directory,
    owner   => $user,
    group   => $group,
    require => [ Exec["move_jboss_home_${user}"] ]
  }

  notice "Creating run.conf file..."
  file { "${jboss_home}/${jboss_dirname}/bin/run.conf":
    content => template("jbossas/jboss${version}/bin/run.conf.erb"),
    owner   => $user,
    group   => $group,
    mode    => 0644,
  }
}

# init.d configuration for CentOS
define jbossas::initd (
    $bind_address = '127.0.0.1',
    $user = 'jboss',
    $group = 'jboss',
    $jboss_home = '/home/jboss',
    $jboss_dirname = 'jboss',
    $jboss_profile_name = 'production',
    $version = '4',
    $bootstrap_jnp_service_port = 1099,
  ){

  #TODO : delete below
  $jbossas_bind_address = $bind_address
  $jbossas_user	        = $user
  $jbossas_home 	    = $jboss_home
  $jbossas_dirname 	    = $jboss_dirname
  $jbossas_profile_name = $jboss_profile_name

  file { "/etc/jboss-${user}":
    ensure => directory,
    owner  => 'root',
    group  => 'root',
  }
  file { "/etc/jboss-${user}/jboss-as.conf":
    content => template("jbossas/jboss${version}/etc/jboss-as.conf.erb"),         #TODO
    owner   => 'root',
    group   => 'root',
    mode    => 0644,
    require => File["/etc/jboss-${user}"],
    notify  => Service["jboss-${user}"],
  }
  file { "/var/run/jboss-${user}":
    ensure => directory,
    owner  => $user,
    group  => $group,
    mode   => 0775,
  }
  file { "/etc/init.d/jboss-${user}":
    content => template("jbossas/jboss${version}/init.d/jboss-as.init.erb"),  #TODO
    owner   => 'root',
    group   => 'root',
    mode    => 0755,
  }
}
  
define jbossas::profile (
    $version = '4',
    $jboss_home = '/home/jboss',
    $jboss_dirname = 'jboss',
    $jboss_profile_name = 'production',
    $user = 'jboss',
    $group = 'jboss',
    $base_dynamic_class_resource_loading_port = 8083,
    $base_bootstrap_jnp_port = 1099,
    $base_rmi_port = 1098,
    $base_rmi_jrmp_invoker_port = 4444,
    $base_pooled_invoker_port = 4445,
    $base_jboss_remoting_connector_port = 4446,
    $base_web_container_http_port = 8080,
    $base_web_container_https_port = 8443,
    $base_web_container_ajp_port = 8009,

) {
  # Create new profile depending on JBoss version
  case $version {
     '4': { profile::jboss4 {"${name}":
                                jboss_home => $jboss_home,
                                jboss_dirname => $jboss_dirname,
                                jboss_profile_name => $jboss_profile_name,
                                user => $user,
                                group => $group,
                                base_dynamic_class_resource_loading_port => $base_dynamic_class_resource_loading_port,
                                base_bootstrap_jnp_port => $base_bootstrap_jnp_port,
                                base_rmi_port => $base_rmi_port,
                                base_rmi_jrmp_invoker_port => $base_rmi_jrmp_invoker_port,
                                base_pooled_invoker_port => $base_pooled_invoker_port,
                                base_jboss_remoting_connector_port => $base_jboss_remoting_connector_port,
                                base_web_container_http_port => $base_web_container_http_port,
                                base_web_container_https_port => $base_web_container_https_port,
                                base_web_container_ajp_port => $base_web_container_ajp_port,
            }
     }
     '5': { profile::jboss5 {"${name}": } }
     '6': { profile::jboss6 {"${name}": } }
     '7': { profile::jboss7 {"${name}":
                                jboss_home => $jboss_home,
                                jboss_dirname => $jboss_dirname,
                                jboss_profile_name => $jboss_profile_name,
                                user => $user,
                                group => $group,
                                base_dynamic_class_resource_loading_port => $base_dynamic_class_resource_loading_port,
                                base_bootstrap_jnp_port => $base_bootstrap_jnp_port,
                                base_rmi_port => $base_rmi_port,
                                base_rmi_jrmp_invoker_port => $base_rmi_jrmp_invoker_port,
                                base_pooled_invoker_port => $base_pooled_invoker_port,
                                base_jboss_remoting_connector_port => $base_jboss_remoting_connector_port,
                                base_web_container_http_port => $base_web_container_http_port,
                                base_web_container_https_port => $base_web_container_https_port,
                                base_web_container_ajp_port => $base_web_container_ajp_port,
            }
          }
     default: { profile::jboss4 {"${name}": } }
  }
}

define jbossas::profile::jboss4 (
      $jboss_home = '/home/jboss',
      $jboss_dirname = 'jboss',
      $jboss_profile_name = 'production',
      $user = 'jboss',
      $group = 'jboss',
      $base_dynamic_class_resource_loading_port = 8083,
      $base_bootstrap_jnp_port = 1099,
      $base_rmi_port = 1098,
      $base_rmi_jrmp_invoker_port = 4444,
      $base_pooled_invoker_port = 4445,
      $base_jboss_remoting_connector_port = 4446,
      $base_web_container_http_port = 8080,
      $base_web_container_https_port = 8443,
      $base_web_container_ajp_port = 8009,
) {

    notice "Creating new JBoss custom profile..."
    file{[ "${jboss_home}/${jboss_dirname}/server/${jboss_profile_name}",
           "${jboss_home}/${jboss_dirname}/server/${jboss_profile_name}/deploy",
           "${jboss_home}/${jboss_dirname}/server/${jboss_profile_name}/deploy/jboss-web.deployer" ] :
      ensure 	=> directory,
      owner  	=> $user,
      group  	=> $group,
    }

    notice "-Copying conf, lib directories from default profile..."
    exec { "copy_lib_dir_${user}":
      command         => "/bin/cp -R default/lib ${jboss_profile_name}",
      user            => $user,
      group           => $group,
      cwd             => "${jboss_home}/${jboss_dirname}/server",
      logoutput       => 'on_failure',
      require         => File["${jboss_home}/${jboss_dirname}/server/${jboss_profile_name}"],
      unless          => "/usr/bin/test -d ${jboss_profile_name}/lib",
    }
    exec { "copy_conf_dir_${user}":
      command		  => "/bin/cp -R default/conf ${jboss_profile_name}",
      user		      => $user,
      group           => $group,
      cwd		      => "${jboss_home}/${jboss_dirname}/server",
      logoutput	      => 'on_failure',
      require		  => File["${jboss_home}/${jboss_dirname}/server/${jboss_profile_name}"],
      unless		  => "/usr/bin/test -d ${jboss_profile_name}/conf",
    }

    notice "-Copying deploy files from default profile..."
    exec { "copy_deploy_dir_${user}":
      command         => "/bin/cp -R default/deploy/jboss-web.deployer ${jboss_profile_name}/deploy",
      user            => $user,
      group           => $group,
      cwd             => "${jboss_home}/${jboss_dirname}/server",
      logoutput       => 'on_failure',
      require         => File["${jboss_home}/${jboss_dirname}/server/${jboss_profile_name}/deploy/jboss-web.deployer"],
      unless          => "/usr/bin/test -f ${jboss_profile_name}/deploy/jboss-web.deployer/META-INF/jboss-service.xml",
    }
    exec { "copy_deploy_files_${user}":
      command         => "/bin/cp default/deploy/jbossjca-service.xml default/deploy/jboss-local-jdbc.rar default/deploy/jboss-xa-jdbc.rar default/deploy/jmx-invoker-service.xml default/deploy/sqlexception-service.xml ${jboss_profile_name}/deploy",
      user            => $user,
      group           => $group,
      cwd             => "${jboss_home}/${jboss_dirname}/server",
      logoutput       => 'on_failure',
      require         => File["${jboss_home}/${jboss_dirname}/server/${jboss_profile_name}/deploy/jboss-web.deployer"],
      unless          => "/usr/bin/test -f ${jboss_profile_name}/deploy/jbossjca-service.xml",
    }

    notice "Replacing Log4J config file..."
    file { "${jboss_home}/${jboss_dirname}/server/${jboss_profile_name}/conf/jboss-log4j.xml":
      content => template("jbossas/jboss4/conf/jboss-log4j.xml.erb"),
      owner   => $user,
      group   => $group,
      mode    => 0644,
    }

    notice "-Replacing vars in templates..."

    $dynamic_class_resource_loading_port = $base_dynamic_class_resource_loading_port
    $bootstrap_jnp_port = $base_bootstrap_jnp_port
    $rmi_port = $base_rmi_port
    $rmi_jrmp_invoker_port = $base_rmi_jrmp_invoker_port
    $pooled_invoker_port = $base_pooled_invoker_port
    $jboss_remoting_connector_port = $base_jboss_remoting_connector_port
    $web_container_http_port = $base_web_container_http_port
    $web_container_https_port = $base_web_container_https_port
    $web_container_ajp_port = $base_web_container_ajp_port

    #the only purpse of this condition is ti ensure chaining
    if $dynamic_class_resource_loading_port != undef
        and $bootstrap_jnp_port != undef
        and $rmi_port  != undef
        and $rmi_jrmp_invoker_port  != undef
        and $pooled_invoker_port  != undef
        and $jboss_remoting_connector_port  != undef
        and $pooled_invoker_port  != undef
        and $jboss_remoting_connector_port  != undef
        and $web_container_http_port  != undef
        and $web_container_https_port  != undef
        and $web_container_ajp_port  != undef
    {
      file { "${jboss_home}/${jboss_dirname}/server/${jboss_profile_name}/conf/jboss-service.xml":
        content => template('jbossas/jboss4/conf/jboss-service.xml.erb'),
        owner   => $user,
        group   => $group,
        mode    => 0644,
        require => Exec["copy_deploy_files_${user}"],
      #notify    => Service["jboss-${jbossas::user}"],
      }
      file { "${jboss_home}/${jboss_dirname}/server/${jboss_profile_name}/deploy/jboss-web.deployer/server.xml":
        content => template('jbossas/jboss4/deploy/jboss-web.deployer/server.xml.erb'),
        owner   => $user,
        group   => $group,
        mode    => 0644,
        require => Exec["copy_deploy_dir_${user}"],
      #notify    => Service["jboss-${jbossas::user}"],
      }
    }
}

define jbossas::profile::jboss5 (){
  notice "Not yet implemented"
}

define jbossas::profile::jboss6 (){
  notice "Not yet implemented"
}

define jbossas::profile::jboss7 (
    $user = 'jboss',
    $group = 'jboss',
    $base_dynamic_class_resource_loading_port = 8083,
    $base_bootstrap_jnp_port = 1099,
    $base_rmi_port = 1098,
    $base_rmi_jrmp_invoker_port = 4444,
    $base_pooled_invoker_port = 4445,
    $base_jboss_remoting_connector_port = 4446,
    $base_web_container_http_port = 8080,
    $base_web_container_https_port = 8443,
    $base_web_container_ajp_port = 8009,
) {
  #TODO Replace Sed commands with erb templates
  exec { "jboss-${user}_http_port":
    command   => "/bin/sed -i -e 's/socket-binding name=\"http\" port=\"[0-9]\\+\"/socket-binding name=\"http\" port=\"${http_port}\"/' standalone/configuration/standalone.xml",
    user      => $user,
    group      => $group,
    cwd       => "${jboss_home}/${jboss_dirname}",
    logoutput => 'on_failure',
    #require   => Class['jbossas::install'],
    unless    => "/bin/grep 'socket-binding name=\"http\" port=\"${base_web_container_http_port}\"/' standalone/configuration/standalone.xml",
  }

  exec { "jboss-${user}_https_port":
    command   => "/bin/sed -i -e 's/socket-binding name=\"https\" port=\"[0-9]\\+\"/socket-binding name=\"https\" port=\"${base_web_container_https_port}\"/' standalone/configuration/standalone.xml",
    user      => $user,
    group      => $group,
    cwd       => "${jboss_home}/${jboss_dirname}",
    logoutput => 'on_failure',
    #require   => Class['install'],
    unless    => "/bin/grep 'socket-binding name=\"https\" port=\"${base_web_container_https_port}\"/' standalone/configuration/standalone.xml",
  }
}