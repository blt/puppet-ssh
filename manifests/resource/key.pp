# Creates or destroys ssh keys for users, by key name.
#
# Parameters:
#
#  [*ensure*] - Sets or destroys the key (present|absent)
#   *user*    - Determines which user the key will be made for.
#  [*root*]   - Root directory for key creation. Default /home/USER/.ssh
#  [*bits*]  - Determines the length of the created key. Default 4096.
#  [*passphrase*] - Sets the key passphrase. Default ''.
#  [*type*]   - Sets the key type. Default 'rsa'.
#
define ssh::resource::key($ensure=present, $user, $root="/home/$user/.ssh",
  $bits=4096, $passphrase='', $type='rsa') {
  file { $root:
    ensure => $ensure ? { present => directory, default => absent },
    mode => '0700',
    owner => $user,
    group => $user,
  }

  $keypath = "$root/$title"
  exec { "create ssh-key for $user with name $title":
    command => "ssh-keygen -t $type -b $bits -N '$passphrase' -f $keypath",
    creates => $keypath,
    group => $user,
    user => $user,
    require => [User[$user], File[$root]],
  }
  file {
    $keypath:
      mode => '0600',
      require => Exec["create ssh-key for $user with name $title"];
    "${keypath}.pub":
      mode => '0644',
      require => Exec["create ssh-key for $user with name $title"];
  }
}
