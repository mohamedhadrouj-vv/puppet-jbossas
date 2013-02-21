define jbossas::profile (
    $version = '4',
    $jboss_home = '/home/jboss',
    $jboss_dirname = 'jboss',
    $jboss_profile_path = '/home/jboss/server',
    $jboss_profile_name = 'production',
    $user = 'jboss',
    $group = 'jboss',
    $log_classes = {},
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
  # Create new profile depending on JBoss version
  case $version {
     '4': {
            import "profile-jboss4"
            jbossas::profile::jboss4 {"${name}":
                                jboss_home => $jboss_home,
                                jboss_dirname => $jboss_dirname,
                                jboss_profile_path => $jboss_profile_path,
                                jboss_profile_name => $jboss_profile_name,
                                user => $user,
                                group => $group,
                                log_classes => $log_classes,
                                dynamic_class_resource_loading_port => $dynamic_class_resource_loading_port,
                                bootstrap_jnp_port => $bootstrap_jnp_port,
                                rmi_port => $rmi_port,
                                rmi_jrmp_invoker_port => $rmi_jrmp_invoker_port,
                                pooled_invoker_port => $pooled_invoker_port,
                                jboss_remoting_connector_port => $jboss_remoting_connector_port,
                                web_container_http_port => $web_container_http_port,
                                web_container_https_port => $web_container_https_port,
                                web_container_ajp_port => $web_container_ajp_port,
            }
     }
     '5': {
            import "profile-jboss5"
            jbossas::profile::jboss5 {"${name}": }
     }
     '6': {
            import "profile-jboss6"
            jbossas::profile::jboss6 {"${name}": }
     }
     '7': { import "profile-jboss7"
            jbossas::profile::jboss7 {"${name}":
                                jboss_home => $jboss_home,
                                jboss_dirname => $jboss_dirname,
                                jboss_profile_path => $jboss_profile_path,
                                jboss_profile_name => $jboss_profile_name,
                                user => $user,
                                group => $group,
                                log_classes => $log_classes,
                                dynamic_class_resource_loading_port => $dynamic_class_resource_loading_port,
                                bootstrap_jnp_port => $bootstrap_jnp_port,
                                rmi_port => $rmi_port,
                                rmi_jrmp_invoker_port => $rmi_jrmp_invoker_port,
                                pooled_invoker_port => $pooled_invoker_port,
                                jboss_remoting_connector_port => $jboss_remoting_connector_port,
                                web_container_http_port => $web_container_http_port,
                                web_container_https_port => $web_container_https_port,
                                web_container_ajp_port => $web_container_ajp_port,
            }
          }
     default: { jbossas::profile::jboss4 {"${name}": } }
  }
}