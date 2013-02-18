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

  file { "/var/run/jboss-${user}":
    ensure => directory,
    owner  => $user,
    group  => $group,
    mode   => 0775,
  }
}