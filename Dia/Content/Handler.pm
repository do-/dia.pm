no warnings;

CGI::Simple::_initialize_globals ();
	
$CGI::Simple::USE_PARAM_SEMICOLONS = 0;
$CGI::Simple::DISABLE_UPLOADS = 1;
$CGI::Simple::POST_MAX = -1;

################################################################################

sub set_cookie {

	my $cookie = CGI::Simple::Cookie -> new (@_);
	
	unless ($cookie) {
	
		warn "WARNING: no cookie set for " . Data::Dumper::Dumper (\@_);
		
		return;
	
	}

	$_HEADERS -> push_header ('Set-Cookie' => $cookie -> as_string);

}

#################################################################################

sub get_request {

	our $_HEADERS = HTTP::Headers -> new;
	
	our $r = {Q => CGI::Simple -> new};
	
	our %_COOKIES = CGI::Simple::Cookie -> parse ($r -> {Q} -> http ('Cookie'));

	$r -> {Q} -> parse_query_string ();

	our %_REQUEST = $r -> {Q} -> Vars;

}

################################################################################

sub send_http_header {
	
	print $_HEADERS -> as_string;
		
	print "\015\012";
	
}

#################################################################################

sub get_request_problem {

	get_request (@_);

	$ENV {REQUEST_METHOD} eq 'POST' or return 405;

	my $enctype = $r -> {Q} -> http ('Content-Type');

	my $enctype_handlers = {
		'application/json' => {
			code => sub {
				setup_json ();
				%_REQUEST = (%_REQUEST, %{$_JSON -> decode (shift)});
			},
			message => 'Wrong JSON',
		},
		'text/plain' => {
			code => sub {
				setup_json ();
				%_REQUEST = (%_REQUEST, %{$_JSON -> decode (shift)});
			},
			message => 'Wrong JSON',
		},
		'application/octet-stream' => {
			code => sub {
				%_REQUEST = (%_REQUEST, chunk => shift);
			},
			message => 'Wrong request',
		},
	};

	grep { $enctype eq $_ } keys %$enctype_handlers
		or return (400 => 'Wrong Content-Type');

	Encode::_utf8_on ($_) foreach (values %_REQUEST);

	if (my $postdata = delete $_REQUEST {POSTDATA}) {

		my $hdl = $enctype_handlers -> {$enctype};

		eval { $hdl -> {code}($postdata) };

		$@ and return (400 => $hdl -> {message});

	}

	foreach my $k ($r -> {Q} -> http) {
	
		$k =~ /HTTP_X_REQUEST_PARAM_/ or next;
		
		my $s = uri_unescape ($r -> {Q} -> http ($k));
		
		Encode::_utf8_on ($s);
		
		$_REQUEST {data} -> {lc $'} = $s;
	
	}
	
	undef;

}

#################################################################################

sub is_request_ok {

	my ($code, $message) = get_request_problem (@_);
	
	$code or return 1;

	$_HEADERS -> header (Status => $code);

	send_http_header ();

	print ($message);	
	
	warn "Request problem $code $message\n";
	
	return 0;
	
}

################################################################################

sub out_html {

	my ($options, $html) = @_;

	$html and !$_REQUEST {__response_sent} or return;

	__profile_in ('core.out_html'); 

	$html = Encode::encode ('utf-8', $html);

	return print $html if $_REQUEST {__response_started};
	
	$_HEADERS -> header ('Content-Length' => (my $length = length $html));

	send_http_header ();

	print $html;
	
	$_REQUEST {__response_sent} = 1;

	__profile_out ('core.out_html' => {label => "$length bytes"});

}

################################################################################

sub out_json ($) {
	
	my ($page) = @_;

	$_HEADERS -> header ('Content-Type' => 'application/json');

	eval {out_html ({}, $_JSON -> encode ($page))};

	$@ or return;
	
	$@ =~ /^encountered CODE/ or die $@;

	my %content = %{delete $page -> {content}};

	my $json_page = $_JSON -> encode ($page); chop $json_page;
	
	my @c = (); while (my ($k, $v) = each %content) {$c [CODE eq ref $v] -> {$k} = $v}

	my $json_content = $_JSON -> encode ($c [0]); chop $json_content;
				
	send_http_header ();

	print $json_page;
	print ',"content":';
	print $json_content;

	while (my ($k, $v) = each %{$c [1]}) {
		print qq{,"$k":"}; #"
		&$v ();
		print '"';
	}
	
	print '}}';

}

#################################################################################

sub setup_json {

	our $_JSON ||= JSON -> new -> allow_nonref (1) -> allow_blessed (1);

}

1;