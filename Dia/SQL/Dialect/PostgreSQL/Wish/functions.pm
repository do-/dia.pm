#############################################################################

sub wish_to_actually_create_functions {

	my ($items) = @_;
	
	foreach my $i (@$items) {

		sql_do ("$i->{code}");

	}

}

1;