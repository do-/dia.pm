require JSON;

my $fn = $ENV {DIA_PM_CONFIGURATION_FILE_PATH} || 'conf/elud.json';
open (I, $fn) or die "Can't read $fn: $!";
my $json = join '', grep /^[^\#]/, (<I>);
close (I);

our $preconf = JSON::decode_json ($json);