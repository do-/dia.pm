my $fn = "/etc/init.d/$preconf->{fcgi}->{name}";

-f $fn and die "$fn already exists! Abort installation.\n";

open (F, ">$fn") or die "Can't write to $fn:$!\n";

print F <<EOF;
#! /bin/bash
### BEGIN INIT INFO
# Provides:          $preconf->{fcgi}->{name}
# Required-Start:    \$nginx
# Required-Stop:     \$nginx
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: $preconf->{fcgi}->{name} Application starter
# Description:       $preconf->{fcgi}->{name} Application starter
### END INIT INFO#

USER=www-data
PERL_PATH=$preconf->{_}->{path}->{perl}
DIA_PATH=$preconf->{_}->{path}->{dia}
APP_PATH=$preconf->{_}->{path}->{app}
LOG_PATH=$preconf->{_}->{path}->{app}/logs/error.log

CMD="\$PERL_PATH -I\$DIA_PATH -MDia::Server::fork -e"

cd \$APP_PATH

PORT=`\$CMD 'o port'`
PID_PATH=`\$CMD 'o pidfile'`

function act {
    echo -n "\$1 $preconf->{fcgi}->{name}... ";
    su -m -l \$USER -c "\$CMD '\$2' 2>>\$LOG_PATH";
    case "\$?" in
	0) echo -e "\033[0;32m[OK]\033[0m"     ;;
	*) echo -e "\033[0;31m[NOT OK]\033[0m" ;;
    esac
}

case "\$1" in

  status) \$CMD 'status'      ;;

  start)
  	cd \$APP_PATH
  	cd ..
  	cd front
  	grunt build
  	cd \$APP_PATH
  	act Starting start ;;

  stop)   act Stopping stop  ;;

  restart|force-reload)
    \$0 stop;
    \$0 start;
    ;;

  *)
    echo "Usage \$0 {status|start|stop|restart}";
    exit 1;
    ;;

esac

exit 0;
EOF

close (F);

`chmod a+x $fn`;

print <<EOT;
Now try:
    $fn start
    $fn status
    $fn stop
EOT

1;