package Dia::Loader;
use Cwd;

################################################################################

sub import {

	package APP;

	do 'Dia/Conf.pm';

	my $generic_path = __FILE__; $generic_path =~ s{Loader.pm}{GenericApplication};
	
	our $PACKAGE_ROOT = [Cwd::abs_path ('lib'), $generic_path];
			
	unshift (@INC, $PACKAGE_ROOT -> [0]);

	require Dia;

}

1;