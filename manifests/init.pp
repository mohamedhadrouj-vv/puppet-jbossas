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

}