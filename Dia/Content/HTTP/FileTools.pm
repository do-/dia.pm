################################################################################

sub print_as_data_uri {

	my ($path) = @_;	

	open (FILE, $path) or die "$!";

	binmode FILE;

	my $buf;
	
	my $is_virgin = 1;

	while (read (FILE, $buf, 60*57)) {
	
		if ($is_virgin) {
			print 'image/';
			print $buf =~ /^GIF/ ? 'gif' : $buf =~ /^.PNG/ ? 'png' : 'jpeg';
			print ';base64,';
		}

		print MIME::Base64::encode_base64 ($buf, '');
		
		$is_virgin = 0;

	}	

	close FILE;

}

################################################################################

sub download_file_header {

	my ($options) = @_;	

	$_HEADERS -> header (Status => 200);

	$options -> {file_name} =~ s{.*\\}{};
		
	my $type = 
		$options -> {charset} ? $options -> {type} . '; charset=' . $options -> {charset} :
		$options -> {type};

	$type ||= 'application/octet-stream';

	my $path = $options -> {path};
	
	my $start = 0;
	
	my $content_length = $options -> {size};
	
	if (!$content_length && $options -> {path}) {
	
		$content_length = -s $options -> {path};
	
	}
		
	my $range_header = $r -> {Q} -> http ('Range');

	if ($range_header =~ /bytes=(\d+)/) {
		$start = $1;
		my $finish = $content_length - 1;
		$_HEADERS -> header ('Content-Range' => "bytes $start-$finish/$content_length");
		$content_length -= $start;
	}

	$_HEADERS -> header ('Content-Type' => $type);
	
	if ($options -> {file_name} && !$options -> {no_force_download}) {
		$options -> {file_name} =~ s/\?/_/g unless ($ENV {HTTP_USER_AGENT} =~ /MSIE 7/);
		$_HEADERS -> header ('Content-Disposition' => "attachment;filename=" . uri_escape ($options -> {file_name}));
	}

	if ($content_length > 0) {
		$_HEADERS -> header ('Content-Length' => $content_length);
		$_HEADERS -> header ('Accept-Ranges'  => 'bytes');
	} 
	
	$_HEADERS -> remove_header ('Content-Encoding');
	
	send_http_header ();

	$_REQUEST {__response_sent} = 1;
	
	return $start;

}

################################################################################

sub download_file {

	my ($options) = @_;	

	my $path = $options -> {path};
	
	-f $path or die "File not found: $path\n";

	my $start = download_file_header (@_);
	
	my $buf;

	open (F, $path) or die ("Can't open file $path: $!");
	binmode F;
	seek (F, $start, 0);
	while (read (F, $buf, 8192)) { print $buf }
	close F;
	
}

1;