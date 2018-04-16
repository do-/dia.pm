package APP;
use Cwd;
use Dia;

################################################################################

sub import {

	do 'Dia/Conf.pm'; die $@ if $@;

	my $generic_path = __FILE__; $generic_path =~ s{Loader.pm}{GenericApplication};
	
	our $PACKAGE_ROOT = [Cwd::abs_path ('lib'), $generic_path];
			
	unshift (@INC, $PACKAGE_ROOT -> [0]);
				
	require Dia::Content::Mail if $APP::preconf -> {mail};

}

1;