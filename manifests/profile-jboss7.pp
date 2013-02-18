define jbossas::profile::jboss7 (
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
  #TODO Replace Sed commands with erb templates
  exec { "jboss-${user}_http_port":
    command   => "/bin/sed -i -e 's/socket-binding name=\"http\" port=\"[0-9]\\+\"/socket-binding name=\"http\" port=\"${http_port}\"/' standalone/configuration/standalone.xml",
    user      => $user,
    group      => $group,
    cwd       => "${jboss_home}/${jboss_dirname}",
    logoutput => 'on_failure',
    #require   => Class['jbossas::install'],
    unless    => "/bin/grep 'socket-binding name=\"http\" port=\"${web_container_http_port}\"/' standalone/configuration/standalone.xml",
  }

  exec { "jboss-${user}_https_port":
    command   => "/bin/sed -i -e 's/socket-binding name=\"https\" port=\"[0-9]\\+\"/socket-binding name=\"https\" port=\"${web_container_https_port}\"/' standalone/configuration/standalone.xml",
    user      => $user,
    group      => $group,
    cwd       => "${jboss_home}/${jboss_dirname}",
    logoutput => 'on_failure',
    #require   => Class['install'],
    unless    => "/bin/grep 'socket-binding name=\"https\" port=\"${web_container_https_port}\"/' standalone/configuration/standalone.xml",
  }
}