my $fcgi = $preconf -> {fcgi};

$fcgi -> {name}    or die "fcgi/name is not set\n";
$fcgi -> {pidfile} or die "fcgi/pidfile is not set\n";

my $uname = `uname -a`;

$uname =~ /Debian/ ? run 'Install/Service/Linux/Debian':

	die "Unsupported Linux version: $uname";
