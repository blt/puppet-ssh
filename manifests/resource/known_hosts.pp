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
define ssh::resource::known_hosts($ensure=present, $hosts, $user, $root="/home/$user/.ssh") {
  $hosthash = "$root/host_hash"
  $sed = "sed 's/,/\\n/g'"
  $sha = "sha512sum"
  $awk = "awk '{ print \$1 }'"
  $hashcmd = "sha512sum | $awk"
  $known_hosts = "$root/known_hosts"

  # Create the hosts' hash. When this file is re-created it will trigger the
  # exec of ssh-keyscan, which constructs the known_hosts file.
  exec { "create hash of hosts for $user in $root":
    command => "echo '$hosts' | $sha | $awk > $hosthash",
    unless  => "[ -f $hosthash ] && [ `$sha $hosthash | $awk` = `echo '$hosts' | $sha | $awk | $sha | $awk` ]",
    path => [ "/bin/", "/sbin/" , "/usr/bin/", "/usr/sbin/" ],
  }
  file { $hosthash:
    mode => 0600,
  }

  # Construct the right and proper known_hosts file.
  exec { "create $root/known_hosts":
    command => "echo '$hosts' | $sed | ssh-keyscan -H -f - > $root/known_hosts",
    refreshonly => true,
    subscribe => Exec["create hash of hosts for $user in $root"],
    path => [ "/bin/", "/sbin/" , "/usr/bin/", "/usr/sbin/" ],
  }
  file { "${known_hosts}":
    mode => 0600,
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
