define jbossas::profile::jboss4 (
      $jboss_home = '/home/jboss',
      $jboss_dirname = 'jboss',
      $jboss_profile_path = '/home/jboss/server',
      $jboss_profile_name = 'production',
      $user = 'jboss',
      $group = 'jboss',
      $dynamic_class_resource_loading_port = 8083,
      $bootstrap_jnp_port = 1099,
      $rmi_port = 1098,
      $rmi_jrmp_invoker_port = 4444,
      $pooled_invoker_port = 4445,
      $jboss_remoting_connector_port = 4446,
      $web_container_http_port = 8080,
      $web_container_https_port = 8443,
      $web_container_ajp_port = 8009,
) {

    notice "Creating new JBoss custom profile..."
    file{[ "${jboss_profile_path}/${jboss_profile_name}",
           "${jboss_profile_path}/${jboss_profile_name}/deploy",
           "${jboss_profile_path}/${jboss_profile_name}/deploy/jboss-web.deployer" ] :
      ensure 	=> directory,
      owner  	=> $user,
      group  	=> $group,
    }

    notice "-Copying conf, lib directories from default profile..."
    exec { "copy_lib_dir_${user}":
      command         => "/bin/cp -R default/lib ${jboss_profile_path}/${jboss_profile_name}",
      user            => $user,
      group           => $group,
      cwd             => "${jboss_home}/${jboss_dirname}/server",
      logoutput       => 'on_failure',
      require         => File["${jboss_profile_path}/${jboss_profile_name}"],
      unless          => "/usr/bin/test -d ${jboss_profile_path}/${jboss_profile_name}/lib",
    }
    exec { "copy_conf_dir_${user}":
      command		  => "/bin/cp -R default/conf ${jboss_profile_path}/${jboss_profile_name}",
      user		      => $user,
      group           => $group,
      cwd		      => "${jboss_home}/${jboss_dirname}/server",
      logoutput	      => 'on_failure',
      require		  => File["${jboss_profile_path}/${jboss_profile_name}"],
      unless		  => "/usr/bin/test -d ${jboss_profile_path}/${jboss_profile_name}/conf",
    }

    notice "-Copying deploy files from default profile..."
    exec { "copy_deploy_dir_${user}":
      command         => "/bin/cp -R default/deploy/jboss-web.deployer ${jboss_profile_path}/${jboss_profile_name}/deploy",
      user            => $user,
      group           => $group,
      cwd             => "${jboss_home}/${jboss_dirname}/server",
      logoutput       => 'on_failure',
      require         => File["${jboss_profile_path}/${jboss_profile_name}/deploy/jboss-web.deployer"],
      unless          => "/usr/bin/test -f ${jboss_profile_path}/${jboss_profile_name}/deploy/jboss-web.deployer/META-INF/jboss-service.xml",
    }
    exec { "copy_deploy_files_${user}":
      command         => "/bin/cp default/deploy/jbossjca-service.xml default/deploy/jboss-local-jdbc.rar default/deploy/jboss-xa-jdbc.rar default/deploy/jmx-invoker-service.xml default/deploy/sqlexception-service.xml ${jboss_profile_path}/${jboss_profile_name}/deploy",
      user            => $user,
      group           => $group,
      cwd             => "${jboss_home}/${jboss_dirname}/server",
      logoutput       => 'on_failure',
      require         => File["${jboss_profile_path}/${jboss_profile_name}/deploy/jboss-web.deployer"],
      unless          => "/usr/bin/test -f ${jboss_profile_path}/${jboss_profile_name}/deploy/jbossjca-service.xml",
    }

    notice "Replacing Log4J config file..."
    file { "${jboss_profile_path}/${jboss_profile_name}/conf/jboss-log4j.xml":
      content => template("jbossas/jboss4/conf/jboss-log4j.xml.erb"),
      owner   => $user,
      group   => $group,
      mode    => 0644,
    }

    notice "-Replacing vars in templates..."

    #the only purpose of this condition is to ensure chaining
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
      file { "${jboss_profile_path}/${jboss_profile_name}/conf/jboss-service.xml":
        content => template('jbossas/jboss4/conf/jboss-service.xml.erb'),
        owner   => $user,
        group   => $group,
        mode    => 0644,
        require => Exec["copy_deploy_files_${user}"],
      #notify    => Service["jboss-${jbossas::user}"],
      }
      file { "${jboss_profile_path}/${jboss_profile_name}/deploy/jboss-web.deployer/server.xml":
        content => template('jbossas/jboss4/deploy/jboss-web.deployer/server.xml.erb'),
        owner   => $user,
        group   => $group,
        mode    => 0644,
        require => Exec["copy_deploy_dir_${user}"],
      #notify    => Service["jboss-${jbossas::user}"],
      }
    }
}