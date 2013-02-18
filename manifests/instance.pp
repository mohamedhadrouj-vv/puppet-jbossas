# init.d configuration for CentOS
define jbossas::instance (
    $version                                  = 4,
    $bind_address                             = '127.0.0.1',
    $enable_service                           = true,
    $user                                     = 'jboss',
    $group                                    = 'jboss',
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

    #Installs JBoss service
    jbossas::initd { "${name}":
      bind_address                => $bind_address,
      user                        => $user,
      group                       => $group,
      jboss_home                  => $jboss_home,
      jboss_dirname               => $jboss_dirname,
      jboss_profile_name          => $jboss_profile_name,
      version                     => $version,
      bootstrap_jnp_service_port  => $bootstrap_jnp_service_port,
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
      require            => Jbossas::Initd[$name],
    }

    #Cleanup JBoss from default Jaxb libs
    #file {["${jboss_home}/${jboss_dirname}/lib/jaxb-api.jar",
    #       "${jboss_home}/${jboss_dirname}/lib/jaxb-impl.jar",
    #       "${jboss_home}/${jboss_dirname}/lib/endorsed/jaxb-api.jar"] :
    #      ensure   => absent,
    #      require  => Jbossas::Profile["${name}"]
    #}

    file { "/etc/jboss-${user}":
      ensure => directory,
      owner  => 'root',
      group  => 'root',
    }

    file { "/etc/jboss-${user}/jboss-as.conf":
      content => template("jbossas/jboss${version}/etc/jboss-as.conf.erb"),
      owner   => 'root',
      group   => 'root',
      mode    => 0644,
      require => File["/etc/jboss-${user}"],
      notify  => Service["jboss-${user}"],
    }

    file { "/etc/init.d/jboss-${user}":
      content => template("jbossas/jboss${version}/init.d/jboss-as.init.erb"),
      owner   => 'root',
      group   => 'root',
      mode    => 0755,
    }

    #notice "Creating run.conf file..."
    #file { "${jboss_home}/${jboss_dirname}/bin/run.conf":
    #  content => template("jbossas/jboss${version}/bin/run.conf.erb"),
    #  owner   => $user,
    #  group   => $group,
    #  mode    => 0644,
    #}

    #Create JBoss service + set it to run on boot
    service { "jboss-${name}":
      enable    => $enable_service,
      ensure    => $enable_service ? { true => running, default => undef },
      hasstatus => false,
      status    => "/bin/ps aux | /bin/grep ${jboss_home}/${jboss_dirname}/bin/run.sh | /bin/grep ${name} | /bin/grep -v grep",
      require   => Jbossas::Profile[$name],
      #subscribe => File["${jboss_home}/${jboss_dirname}/server/${jboss_profile_name}/deploy/jboss-web.deployer/server.xml",
      #                  "${jboss_home}/${jboss_dirname}/server/${jboss_profile_name}/deploy/jboss-web.deployer/META-INF/jboss-service.xml"],
    }
}