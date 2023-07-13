use FCGI;
use IO::File;
use POSIX ":sys_wait_h", 'setsid';
use Carp;

$SIG {__DIE__} = \&Carp::confess;

################################################################################

sub o ($) {
	my %o = options_unix ();
	print $o {$_[0]}
}

################################################################################

sub options_unix {

	do 'Dia/Conf.pm';

	my %options = %{$preconf -> {fcgi}};

	$options {address}      ||= $options {port} ? ":$options{port}" : '/tmp/elud';
	$options {pidfile}      ||= '/var/run/elud.pid';
	$options {backlog}      ||= 1024;
	$options {processes}    ||= 20;
	$options {timeout}      ||= 1;
	$options {kill_timeout} ||= 1;
	$options {signal}       ||= 15;
	$options {foreground}   ||= 0;

	return %options;

}

################################################################################

sub pid_unix {

	my %options = options_unix ();
	
	-f $options {pidfile} or return undef;

	open (PIDFILE, "$options{pidfile}") or die "Can't read $options{pidfile}:$!\n";
	my $pid = <PIDFILE>;
	close (PIDFILE);

	if (!kill (0, $pid)) {

		print STDERR "Process $pid is already dead, but pidfile is still remaining...\n";

		unlink $options {pidfile};

		die "Can't remove stale pidfile $options{pidfile}.\n" if -f $options {pidfile};

		print STDERR "Stale pidfile $options{pidfile} removed.\n";

		return undef;

	}

	return $pid;

}

################################################################################

sub stop {

	my %options = options_unix ();

	$options {pid_to_stop} = pid_unix (%options);

	if (!$options {pid_to_stop}) {

		print STDERR "Can't open $options{pidfile}.\n";

		return;
		
	}
	
	keep_trying_to_stop (%options);

}

################################################################################

sub keep_trying_to_stop {

	my %options = @_;
	
	while (1) {
	
		print STDERR "Sending signal $options{signal} to process $options{pid_to_stop}...\n";

		kill ($options {signal}, $options {pid_to_stop});
		
		sleep ($options {kill_timeout});
		
		next if kill (0, $options {pid_to_stop});
		
		print STDERR "OK, it is down.\n";
		
		last;

	}	

}

################################################################################

sub REAPER {

	my $child;

	while (($child = waitpid (-1,WNOHANG)) > 0) {}
	
	$SIG {CHLD} = \&REAPER;
	
	alarm 0;

}

$SIG {CHLD} = \&REAPER;

################################################################################

sub status {

	my %options = options_unix ();
	
	unless (-f $options {pidfile}) {
		print "Not running\n";
		exit 0;
	}
		
	if (my $pid = pid_unix (%options)) {
		print "Running, PID=$pid\n";
		exit 0;
	}

	print "Not running, but the $options{pidfile} still exists\n";

}

################################################################################

sub start {
	
	require Dia::Loader;

	my %options = options_unix ();	
	
	$0 = $options {name} if $options {name};
	
	my $pid = pid_unix (%options); 
	$pid and die "The server is already running, PID=$pid\n";

	APP::import ();
	APP::require_config ();
	APP::sql_reconnect  ();
	APP::require_model  ();
	APP::sql_disconnect ();

	open (PIDFILE, ">$options{pidfile}") or die "Can't write to $options{pidfile}: $!\n";

	chdir '/' or die "Can't chdir to /: $!";

	open STDIN, '/dev/null' or die "Can't read /dev/null: $!";

	open STDOUT, '>/dev/null' or die "Can't write to /dev/null: $!";

	unless ($options {foreground}) {

		defined (my $pid = fork) or die "Can't fork: $!";

		exit if $pid;

	}

	die "Can't start a new session: $!" if setsid == -1;

	print PIDFILE $$;
	close (PIDFILE);

	my %pids = ();

	$SIG {'HUP'} = 'INGNORE';
	
	$SIG {'TERM'} = sub { 
		
		kill (15, keys %pids);

		while (1) { waitpid (-1, WNOHANG) > 0 or last }
				
		pid_unix (%options) == $$ and unlink $options {pidfile};
		
		exit;
		
	};

	my $socket;
	
	eval {
		$socket = FCGI::OpenSocket ($options {address}, $options {backlog});

		$options {address} =~ /^\:/ or chmod 0777, $options {address};

	};
	
	if ($@) {

		unlink $options {pidfile};

		die "$@\n";

	}

	for (; 1; sleep) {
	
		foreach (keys %pids) {
		
			kill (0, $_) or delete $pids {$_};
		
		}
	
		for (1 .. $options {processes} - keys %pids) {
		
			if (my $pid = fork ()) {
			
				$pids {$pid} = 1;
				
				next;
			
			}
			
			$SIG {'TERM'} = 'DEFAULT';

			my $request = FCGI::Request (\*STDIN, \*STDOUT, new IO::File, \%ENV, $socket);

			while ($request -> Accept >= 0) {

				eval {APP::handler ()};

				warn $@ if $@;

			}

		}

	}

}

1;