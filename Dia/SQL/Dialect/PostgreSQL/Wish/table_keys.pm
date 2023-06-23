#############################################################################

sub wish_to_clarify_demands_for_table_keys {	

	my ($i, $options) = @_;
	
	$i -> {global_name} = 'ix_' . $options -> {table} . '_' . $i -> {name};

	unless (ref $i -> {parts} eq ARRAY) {

		if ($i -> {parts} =~ /\!$/) {

			chop $i -> {parts};
			
			$i -> {is_uniq} = 1;

			$i -> {is_partial} = 1;

			$i -> {where} = 'WHERE fake = 0';

		}

		if ($i -> {parts} =~ /^(.*?)\s+(WHERE.*)$/) {

			$i -> {parts} = $1;

			$i -> {is_partial} = 1;

			$i -> {where} = $2;

		}

		$i -> {parts} = [split /\s*\,\s*/, $i -> {parts}];

	}

	foreach my $part (@{$i -> {parts}}) {
	
		$part = lc $part;

		$part =~ s{^\s+|\s+$}{}gsm;
		
		$part =~ s{(\w+)\((\d+)\)}{substring($1 from 1 for $2)};

	}

}

################################################################################

sub wish_to_explore_existing_table_keys {

	my ($options) = @_;

	$options -> {_cache} or sql_select_loop ("SELECT * FROM pg_indexes WHERE schemaname = current_schema () AND indexname NOT LIKE '%_pkey'", sub {

		my $def;

		if ($i -> {indexdef} =~ /\(\s*(.*?)\s*\)/) {

			$def = $1;

		}
		else {
		
			darn $i and die "Can't parse index definition (see above)\n";
		
		}
		
		my $global_name = lc $i -> {indexname};
		
		my $d = {
					
			parts       => [split /\s*\,\s*/, lc $def],
			
			global_name => $global_name,

			name        => substr $global_name, (4 + length $i -> {tablename})
			
		};
		
		if ($i -> {indexdef} =~ /UNIQUE(.+)WHERE/i) {

			$d -> {is_uniq} = 1;

		}

		if ($i -> {indexdef} =~ /WHERE \((.+?)\)$/i) {

			$d -> {is_partial} = 1;

			$d -> {where} = 'WHERE '.$1;

		}

		$options -> {_cache} -> {$i -> {tablename}} -> {$global_name} = $d;

	});

	$options -> {_cache} -> {$options -> {table}};

}

#############################################################################

sub wish_to_actually_create_table_keys {	

	my ($items, $options) = @_;
	
	my $concurrently = $self -> {db} -> {AutoCommit} ? 'CONCURRENTLY' : '';
	
	foreach my $i (@$items) {

		my ($unique, $where) = ('', '');

		$unique = 'UNIQUE' if $i -> {is_uniq};

		$where = $i -> {where} if $i -> {is_partial};

		sql_do ("CREATE $concurrently $unique INDEX $i->{global_name} ON $options->{table} (@{[ join ', ', @{$i -> {parts}} ]}) $where");
	
	}

}

1;