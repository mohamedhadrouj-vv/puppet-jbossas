# init.d configuration for CentOS
define jbossas::instance (
    $ver                                      = 4,
    $bind_address                             = '127.0.0.1',
    $enable_service                           = true,
    $ensure_service                           = undef,
    $user                                     = 'jboss',
    $group                                    = 'jboss',
    $log_classes                              = {},
    $jboss_home                               = '/home/',
    $jboss_dirname                            = 'jboss',
    $jboss_profile_path                       = '/home/jboss/server',
    $jboss_profile_name                       = 'production',
    $jvm_xms                                  = 128,
    $jvm_xmx                                  = 512,
    $jvm_maxpermsize                          = 256,
    $java_opts                                = {},
    $dynamic_class_resource_loading_port      = 8083,
    $bootstrap_jnp_service_port               = 1099,
    $rmi_port                                 = 1098,
    $rmi_jrmp_invoker_port                    = 4444,
    $pooled_invoker_port                      = 4445,
    $jboss_remoting_connector_port            = 4446,
    $web_container_http_port                  = 8080,
    $web_container_https_port                 = 8443,
    $web_container_ajp_port                   = 8009,
){

    #Installs Jboss Init.d file
    jbossas::initd { "${name}":
      ver                         => $ver,
      user                        => $user,
      jboss_home                  => $jboss_home,
      jboss_dirname               => $jboss_dirname,
      jboss_profile_name          => $jboss_profile_name,
      jboss_profile_path          => $jboss_profile_path,
    }

    #Create a custom JBoss profile
    jbossas::profile { "${name}":
      jboss_home         => $jboss_home,
      jboss_dirname      => $jboss_dirname,
      jboss_profile_path => $jboss_profile_path,
      jboss_profile_name => $jboss_profile_name,
      bootstrap_jnp_port => $bootstrap_jnp_service_port,
      user               => $user,
      group              => $group,
      log_classes        => $log_classes,
      require            => Jbossas::Initd[$name],
    }

    file { "${jboss_profile_path}/${jboss_profile_name}/conf/jboss-as.conf":
      content => template("jbossas/jboss${ver}/conf/jboss-as.conf.erb"),
      owner   => $user,
      group   => $group,
      mode    => 0644,
      require => File["${jboss_profile_path}/${jboss_profile_name}/conf"],
      #notify  => Service["jboss-${user}"],
    }

    #notice "Creating run.conf file..."
    file { "${jboss_profile_path}/${jboss_profile_name}/conf/run.conf":
      content => template("jbossas/jboss${ver}/conf/run.conf.erb"),
      owner   => $user,
      group   => $group,
      mode    => 0644,
      require => File["${jboss_profile_path}/${jboss_profile_name}/conf"],
    }

    #Create JBoss service + set it to run on boot
    service { "jboss-${name}":
      enable    => $enable_service,
      ensure    => $ensure_service,
      hasstatus => false,
      status    => "/bin/ps aux | /bin/grep ${jboss_home}/${jboss_dirname}/bin/run.sh | /bin/grep ${name} | /bin/grep -v grep",
      require   => [ Jbossas::Initd[$name], Jbossas::Profile[$name], File["${jboss_profile_path}/${jboss_profile_name}/conf/run.conf"] ],
      #subscribe => File["${jboss_home}/${jboss_dirname}/server/${jboss_profile_name}/deploy/jboss-web.deployer/server.xml",
      #                  "${jboss_home}/${jboss_dirname}/server/${jboss_profile_name}/deploy/jboss-web.deployer/META-INF/jboss-service.xml"],
    }
}
