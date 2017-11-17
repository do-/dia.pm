use FCGI;
use IO::File;

################################################################################

sub start {
		
	do 'Dia/Conf.pm';

	require Dia::Loader;
	
	APP::import ();
	APP::require_config ();
	APP::sql_reconnect  ();
	APP::require_model  ();

	my $f = $APP::preconf -> {fcgi};
	
	$f -> {address} ||= ':' . $f -> {port};
	$f -> {backlog} ||= 1024;
		
	my $socket = FCGI::OpenSocket ($f -> {address}, $f -> {backlog});

	my $request = FCGI::Request (\*STDIN, \*STDOUT, new IO::File, \%ENV, $socket);

	while ($request -> Accept >= 0) {

		eval {APP::handler ()};
		
		warn $@ if $@;

	}

}

1;