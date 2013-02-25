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
  $user = 'jboss',
  $group = 'jboss',
  $download_dir = '/tmp/jboss',
  $jboss_home = '/home/jboss',
  $jboss_dirname = 'jboss',
  $jsf_api_version = '1.2_15',
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
    }

    #Cleanup JBoss from default Jaxb libs
    file {["${jboss_home}/${jboss_dirname}/lib/jaxb-api.jar",
           "${jboss_home}/${jboss_dirname}/lib/jaxb-impl.jar",
           "${jboss_home}/${jboss_dirname}/lib/endorsed/jaxb-api.jar"] :
      ensure   => absent,
      require  => Jbossas::Install["${name}"]
    }

    #Download JSF api files
    $local_jsf_dir = "${jboss_home}/${jboss_dirname}/server/default/deploy/jboss-web.deployer/jsf-libs"
    $jsf_api_url = "http://repo1.maven.org/maven2/javax/faces/jsf-api/${jsf_api_version}/jsf-api-${jsf_api_version}.jar"
    $jsf_api_impl_url = "http://repo1.maven.org/maven2/javax/faces/jsf-impl/${jsf_api_version}/jsf-impl-${jsf_api_version}.jar"

    #Download the JSF libs
    exec { "jsf_api_${name}":
      command   => "curl --progress-bar -O ${jsf_api_url} -L",
      cwd       => "${local_jsf_dir}",
      path      => "/usr/bin/",
      user      => $user,
      logoutput => true,
      timeout   => 0,
      unless    => "test -f jsf-api-${jsf_api_version}.jar",
      require   => [ Package['curl'] ],
    }

    exec { "jsf_api_impl_${name}":
      command   => "curl --progress-bar -O ${jsf_api_impl_url} -L",
      cwd       => "${local_jsf_dir}",
      path      => "/usr/bin/",
      user      => $user,
      logoutput => true,
      timeout   => 0,
      unless    => "test -f jsf-impl-${jsf_api_version}.jar",
      require   => [ Package['curl'] ],
    }

    file { ["${local_jsf_dir}/jboss-faces.jar",
            "${local_jsf_dir}/jsf-api-${jsf_api_version}.jar",
            "${local_jsf_dir}/jsf-impl-${jsf_api_version}.jar"]:
      ensure  => present,
      purge   => true,
      recurse => true,
      owner   => $user,
      group   => $group,
      require => [ Exec["jsf_api_impl_${name}"], Exec["jsf_api_${name}"] ],
    }

    $local_jbossweb_dir = "${jboss_home}/${jboss_dirname}/server/default/deploy/jboss-web.deployer/"
    $tomcat_juli_url = "http://mirrors.ibiblio.org/pub/mirrors/maven2/org/apache/tomcat/extras/juli/6.0.13/juli-6.0.13.jar"
    $tomcat_extras_url = "http://xebia-france.googlecode.com/files/xebia-tomcat-extras-1.0.0.jar"
    #Download the Tomcat-Juli
    exec { "download_tomcat_juli_${name}":
      command   => "curl --progress-bar -O ${tomcat_juli_url} -L",
      cwd       => "${local_jbossweb_dir}",
      path      => "/usr/bin/",
      user      => $user,
      logoutput => true,
      timeout   => 0,
      unless    => "test -f juli-6.0.13.jar",
      require   => [ Package['curl'] ],
    }

    #Download the Tomcat-Juli
    exec { "download_tomcat_extras_${name}":
      command   => "curl --progress-bar -O ${tomcat_extras_url} -L",
      cwd       => "${local_jbossweb_dir}",
      path      => "/usr/bin/",
      user      => $user,
      logoutput => true,
      timeout   => 0,
      unless    => "test -f xebia-tomcat-extras-1.0.0.jar",
      require   => [ Package['curl'] ],
    }

}