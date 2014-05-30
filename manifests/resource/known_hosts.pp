# Creates, modifies or destroys an ssh known_hosts file.
#
# This resource will not create the root directory nor the user: construct them
# ahead of time.
#
# An auxiliary file containing a single hash of the provided hosts will be
# created in the root directory. Please do not delete it; all security
# precautions comiserate to those taken by known_hosts are taken with regard to
# the hosts' hash file.
#
# Parameters:
#
#  [*ensure*] - Sets the presence of the known_hosts file (present|absent).
#   *hosts*   - Comma separated list of hostnames to compile into known_hosts file.
#   *user*    - User to create known_hosts file for.
#  [*root*]   - Parent directory known_hosts file. Default /home/USER/.ssh
define ssh::resource::known_hosts($ensure=present, $hosts, $user, $root="/home/$user/.ssh", $known_hosts="$root/known_hosts", $known_hosts_mode='0600') {
  $hosthash = "$root/host_hash"
  $sed = "sed 's/,/\\n/g'"
  $sha = 'sha512sum'
  $awk = "awk '{ print \$1 }'"

  # Create the hosts' hash. When this file is re-created it will trigger the
  # exec of ssh-keyscan, which constructs the known_hosts file.
  exec { "create hash of hosts for $user in $root":
    path => '/bin:/usr/bin:/bin:/usr/sbin:/sbin',
    command => "echo '$hosts' | $sha | $awk > $hosthash",
    unless  => "[ -f $hosthash ] && [ `cat $hosthash` = `echo '$hosts' | $sha | $awk` ]",
  }
  file { $hosthash:
    mode => 0600,
  }

  # Construct the right and proper known_hosts file.
  exec { "create ${known_hosts}":
    path => '/bin:/usr/bin:/bin:/usr/sbin:/sbin',
    command => "echo '$hosts' | $sed | ssh-keyscan -H -f - > ${known_hosts}",
    refreshonly => true,
    subscribe => Exec["create hash of hosts for $user in $root"],
  }
  file { "${known_hosts}":
    mode => $known_hosts_mode,
  }

  ## Ensure that all files and execs get the correct user/group combinations.
  Exec {
    user => $user,
    group => $user,
    require => File[$root],
  }
  File {
    ensure => $ensure ? { present => file, default => absent },
    owner => $user,
    group => $user,
  }
  file{ $root:
   ensure => directory
  }
}
