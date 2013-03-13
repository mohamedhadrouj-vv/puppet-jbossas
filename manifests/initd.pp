# init.d configuration for CentOS
define jbossas::initd (
    $version = '4',
    $user = 'jboss',
    $jboss_home = '/home/jboss',
    $jboss_dirname = 'jboss',
    $jboss_profile_name = 'production',
    $jboss_profile_path = '/home/jboss',
  ){

  file { "/etc/init.d/jboss-${user}":
    content => template("jbossas/jboss${version}/init.d/jboss-as.init.erb"),
    owner   => 'root',
    group   => 'root',
    mode    => 0755,
  }

}