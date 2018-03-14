#############################################################################

sub wish_to_actually_update_table_data {	

	my ($items, $options) = @_;

	@$items > 0 or return;

	my @cols = ();
	my @prms = ();
	
	foreach my $col (grep {$_ ne 'id'} keys %{$items -> [0]}) {
		
		push @cols, sql_field_name ($col) . '=?';
		push @prms, [ map {$_ -> {$col}} @$items];
	
	}
	
	push @prms, [ map {$_ -> {id}} @$items];
	
	my $sql = "UPDATE $options->{table} SET " . (join ', ', @cols) . " WHERE id = ?";
		
	__profile_in ('sql.prepare_execute');

	my $sth = $db -> prepare ($sql);

	$sth -> execute_array ({ArrayTupleStatus => \my @tuple_status}, @prms);
	
	__profile_out ('sql.prepare_execute', {label => $sql . ' ' . Dumper (\@prms)});

	$sth -> finish;

}

#############################################################################

sub wish_to_actually_create_table_data {	

	my ($items, $options) = @_;

	@$items > 0 or return;
	
	if (exists $items -> [0] -> {id}) {

		sql_do_insert ($options -> {table} => $_) foreach sort {$a -> {id} <=> $b -> {id}} @$items;
	
	}
	else {

		my @cols = ();
		my @prms = ();

		foreach my $col (keys %{$items -> [0]}) {

			push @cols, $col;
			push @prms, [ map {$_ -> {$col}} @$items];

		}
		
		my $sql = "INSERT INTO $options->{table} (" . (join ', ', @cols) . ") VALUES (" . (join ', ', map {'?'} @cols) . ")";

		__profile_in ('sql.prepare');

		my $sth = $db -> prepare ($sql);

		__profile_out ('sql.prepare', {label => $sql});

		__profile_in ('sql.execute');

		$sth -> execute_array ({ArrayTupleStatus => \my @tuple_status}, @prms);

		__profile_out ('sql.execute', {label => $sql . ' ' . Dumper (\@prms)});

		$sth -> finish;

	}
	
}

1;