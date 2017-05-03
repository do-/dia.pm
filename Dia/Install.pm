use Cwd;
use Data::Dumper;

sub run ($) {

	do "Dia/$_[0].pm"; 

	die $@ if $@;
	
}

sub read_conf {

	run Conf;

	my $path = $INC {'Dia/Install.pm'};
	$path =~ s{[\/]Dia[\/]Install\.pm$}{};
	
	$preconf -> {_} -> {path} -> {dia}  = $path;
	$preconf -> {_} -> {path} -> {perl} = $^X;
	$preconf -> {_} -> {path} -> {app}  = getcwd ();

}

sub service {

	read_conf ();

	$^O eq 'linux' ? run 'Install/Service/Linux':

		die "Sorry, $^O is not yet supported\n";

}

1;