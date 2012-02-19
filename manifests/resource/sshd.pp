# Enables or disables sshd.
#
# Parameters:
#
#  [*ensure*] - Sets sshd as enabled or disabled (present|absent)
#  [*port*]   - Defines the port sshd will respond over. Default 22.
#
class ssh::resource::sshd($ensure=present, $port='22') {
  package { 'sshd':
    name => 'openssh-server',
    ensure => $ensure,
  }

  file { '/etc/ssh/sshd_config':
    ensure => $ensure ? { present => file, default => absent },
    content => template('ssh/sshd_config.erb'),
    require => Package['sshd'],
  }
}
