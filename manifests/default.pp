define append_if_no_such_line($file, $line, $refreshonly = 'false') {
   exec { "/bin/echo '$line' >> '$file'":
      unless      => "/bin/grep -Fxqe '$line' '$file'",
      path        => "/bin",
      refreshonly => $refreshonly,
   }
}

class must-have {
  include apt
  apt::ppa { "ppa:webupd8team/java": }

  exec { 'apt-get update':
    command => '/usr/bin/apt-get update',
    before => Apt::Ppa["ppa:webupd8team/java"],
  }

  exec { 'apt-get update 2':
    command => '/usr/bin/apt-get update',
    require => [ Apt::Ppa["ppa:webupd8team/java"], Package["git-core"] ],
  }

  package { ["vim", "curl", "git-core", "bash"]:
    ensure => present,
    require => Exec["apt-get update"],
    before => Apt::Ppa["ppa:webupd8team/java"],
  }

  package { "oracle-java7-installer":
    ensure => present,
    require => Exec["apt-get update 2"],
  }

  exec { "accept_license":
    command => "echo debconf shared/accepted-oracle-license-v1-1 select true | sudo debconf-set-selections && echo debconf shared/accepted-oracle-license-v1-1 seen true | sudo debconf-set-selections",
    cwd => "/home/vagrant",
    user => "vagrant",
    path => "/usr/bin/:/bin/",
    require => Package["curl"],
    before => Package["oracle-java7-installer"],
    logoutput => true,
  }

  file { "/vagrant/elasticsearch":
    ensure => directory,
    before => Exec["download_elasticsearch"]
  }

  exec { "download_elasticsearch":
    command => "curl -L https://download.elasticsearch.org/elasticsearch/elasticsearch/elasticsearch-0.90.4.tar.gz | tar zx --directory=/vagrant/elasticsearch --strip-components 1",
    cwd => "/vagrant",
    user => "vagrant",
    path => "/usr/bin/:/bin/",
    require => Exec["accept_license"],
    logoutput => true,
  }
}

include must-have
