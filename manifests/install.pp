define jbossas::install (
    $mirror_url = 'http://freefr.dl.sourceforge.net/project/jboss/JBoss/JBoss-4.2.3.GA/jboss-4.2.3.GA-jdk6.zip',
    $version = '4',
    $download_dir = '/tmp/jboss',
    $jboss_home = '/home/jboss',
    $user = 'jboss',
    $group = 'jboss',
    $jboss_dirname = 'jboss',
) {

  ##################
  # Following jBoss version determine mirror url, unzipped dir and checksum
  ##################
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

  #notice "Download URL: ${mirror_url_version}"
  #notice "JBoss AS directory: ${jboss_home}/${jboss_dirname}"

  # Create home folder
  file { "${jboss_home}":
    ensure  => directory,
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
    require   => [ Package['curl'], File["${download_dir}/${name}"], File["${dist_file}.md5sum"] ],
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

  #notice "Creating /var/run dir..."
  file { "/var/run/jboss-${user}":
    ensure => directory,
    owner  => $user,
    group  => $group,
    mode   => 0775,
  }

}