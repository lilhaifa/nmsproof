#!/usr/bin/perl -w
#

#use strict "refs";

$den_device_src = "$ENV{\"HOME\"}"."/dev/nmsproof/data/Den_Networks_Device_Master-Table_1.csv";
$den_device_dest = "$ENV{\"HOME\"}"."/dev/nmsproof/data/Den_Networks_Device_IPaddr.csv";
$den_snmp_dest_base = "$ENV{\"HOME\"}"."/dev/nmsproof/data";
$den_dev_snmpout_src = "$ENV{\"HOME\"}"."/dev/nmsproof/data/den_devices_snmpwalk_list.txt";
$den_dev_snmpout_dest = "$ENV{\"HOME\"}"."/dev/nmsproof/data/den_devices_snmpwalk_oids.csv";
$den_dev_snmptrapd_src = "$ENV{\"HOME\"}"."/dev/nmsproof/test/data/den_ddyadagiri_mux_traps_20231018_1747.log";
$den_dev_snmptrap_dest = "$ENV{\"HOME\"}"."/dev/nmsproof/test/data/den_ddyadagiri_mux_snmptrap_oids.csv";

$fline = "";
@arrx = ();
$fd = "";
$dest = "";
$snmpfx = "snmpwalk -v 2c -c public ";
%DEVDB = ();
$OFDLM = "\|";
$xstr = "";
$ofx = "";
$devip = "";
$trpoid = "";
%TRAPOID = ();
@TGTOIDFIELDS = ("msgBehaviour","msgDetail\\.","msgGenerationTime","msgId","msgPhysicalEntity","msgSourceName","msgSubject","msgText");

sub dosnmpwalk;
sub dowalksumm;
sub runtestpoll;
sub pullpollinfo;
sub pulltrapinfo;
sub runddpunjtest;
sub pulltestrapoids;
sub istgtfdinoid;

#### BEGIN HERE ####

print "executing now...\n";

#runtestpoll();
#dowalksumm();
#pulltrapinfo($den_dev_snmptrapd_src);

#$argx = @ARGV;
#print "received : $argx arguments\n";
#if( $argx != 5)
#  {
#   print "expecting 5 arguments, received $argx, try again\n";
#  exit(1);
# }

#for($i=0;$i<$argx;$i++)
# {
#  print "arg # : $i = $ARGV[$i]\n";
#  }

#runddpunjtest(@ARGV);

#$ofx = open(LOFH,">",$den_dev_snmptrap_dest);

#foreach $devip ( sort keys %TRAPOID )
#  {
#   foreach $oid ( sort keys %{$TRAPOID{$devip}} )
#     {
#      $xstr = "$devip"."$OFDLM"."$oid"."$OFDLM"."${$TRAPOID{$devip}}{$oid}"; 
#      print LOFH "$xstr\n";
#      print "$oid = ${$TRAPOID{$devip}}{$oid}\n";
#     }
#  }

#$ofx = open(LOFH,">",$den_dev_snmpout_dest);

#foreach $devtype ( sort keys %DEVDB )
#  {
#   print "device type = $devtype, poll returned :\n\n";
#   foreach $oid ( sort keys %{$DEVDB{$devtype}} )
#     {
#      $xstr = "$devtype"."$OFDLM"."$oid"."$OFDLM"."${$DEVDB{$devtype}}{$oid}"; 
#      print LOFH "$xstr\n";
#      print "$oid = ${$DEVDB{$devtype}}{$oid}\n";
#     }
#  }

#close(LOFH);

pulltestrapoids();

#foreach $recid ( sort { $a <=> $b } keys %TRAPOID )
# {
#  foreach $oid ( sort keys %{$TRAPOID{$devip}} )
#   {
#    $xstr = "$devip"."$OFDLM"."$oid"."$OFDLM"."${$TRAPOID{$devip}}{$oid}"; 
#    print LOFH "$xstr\n";
#    print "$oid = ${$TRAPOID{$devip}}{$oid}\n";
#   }
# }

print "finished !\n";

exit(0);

#### END HERE ####

sub dosnmpwalk
  {
   my $line;
   #print "$ENV{\"HOME\"}\n";
   #print "$den_device_src\n";

   #open(OFH, ">", $den_device_dest) or die ("not able to open $den_device_dest, error = $!");
   open(IFH, "<", $den_device_src) or die ("not able to open $den_device_src, error = $!");

   while( <IFH> )
     {
       $line = $_;
       chomp($line);
       $line =~ s/\s+$//;
       #    print "rec = $line\n";
       @arrx = split(/,/,$line);
       print "rec array = @arrx\n";
       foreach $fd (@arrx)
         {
          if( $fd =~ /^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}/)
            {
             print "Valid IP Addr = $fd\n";
             $dest = $fd;
             $dest =~ s/\./-/g;
             $dest = "$den_snmp_dest_base"."/"."den_"."$dest"."_snmpwalk_out.txt";
             print "dest = $dest\n";
             $snmpcmd = "$snmpfx"."$fd "."> "."$dest";
             print "cmd = $snmpcmd\n";
             #print OFH "$fd\n";
             last;
	    }
         }
     }
   close(IFH);
   #close(OFH);
   return;
  } # dosnmpwalk 

sub runtestpoll
  {
   $xdate = `date`;
   print "date = $xdate\n";
   $testcmd = "$snmpfx"."127.0.0.1 > ../data/local_127-0-0-1_snmpwalk_out.txt";
   `$testcmd`;
   return;
  } # runtestpoll

sub dowalksumm
  {
   my $thisub = "dowalksumm";
   my $srcf;
   my $line;
   my $retv;

   open(IFH, "<", $den_dev_snmpout_src) or die ("not able to open $den_dev_snmpout_src, error = $!");

   while( <IFH> )
     {
       $line = $_;
       chomp($line);
       $line =~ s/\s+$//;
       #print "snmpwalk src  = $line\n";
       $srcf = "$den_snmp_dest_base"."/"."$line";
       if ( ! -z $srcf )
         {
          #print "$srcf is not empty\n";
         $retv =  pullpollinfo($srcf);
	 print "$thisub :: returned value from $srcf = $retv\n";
	 }
       elsif ( -z $srcf )
         {
	  print "$thisub :: warning : $srcf is empty\n";
	 }
     }
   close(IFH);
   return;
  } #dowalksumm

sub pullpollinfo
  {
    my $thisub = "pullpollinfo";
    my $devoidh;
    my $srcf;
    my $srch;
    my $line;
    my @ax = ();
    my $flag = "";
    my $retv = "not read : duplicate";
    my $devoid = "";
    my $lctr = 0;
    my $strec;
    my $ipid = "";

    #print "$thisub : received arguments : @_\n";
    $srcf = shift(@_);
    print "$thisub :: poll source = $srcf\n";
    #if( $srcf =~ s/(\d{1,3}-\d{1,3}-\d{1,3}-\d{1,3})/)
    #  {
    #    $ipid = $1;
    #    print "$thisub :: IP ID for $srcf = $ipid\n";
    #  }
    $srch = open(SIFH, "<", $srcf);
    while( <SIFH> )
      {
       chomp $_;
       $_ =~ s/\s+$//;
       $line = $_;
       $lctr++;
       @ax = split(/=/,$line);
       $ax[0] =~ s/^\s+//;
       $ax[0] =~ s/\s+$//;
       $ax[1] =~ s/^\s+//;
       $ax[1] =~ s/\s+$//;
       print "$thisub :: line ctr = $lctr, rec fd 0 = $ax[0], fd 1 = $ax[1]\n";
       if(( $ax[0] eq "SNMPv2-MIB::sysObjectID.0") && ( ! exists $DEVDB{$ax[1]}))
         {
	  print "$thisub :: creating new hash for $ax[1], start rec = $lctr...\n";
          $DEVDB{$ax[1]} = {};
	  $devoid = $ax[1];
	  $flag = "1";
	  $strec = $lctr;
	  $retv = "read done successfully";
	 }
       if(( exists $DEVDB{$devoid}) && ($lctr > $strec)) 
         {
          print "adding to device type : $devoid...\n";
          ${$DEVDB{$devoid}}{$ax[0]} = $ax[1];
	 }
      }
    close(SIFH);

    return $retv;

  } # pullpollinfo

sub pulltrapinfo
  {
    my $thisub = "pulltrapinfo";
    my $devoidh;
    my $srcf;
    my $srch;
    my $line;
    my @ax = ();
    my @ay = ();
    my @az =();
    my $flag = "";
    my $retv = "1";
    my $devoid = "";
    my $lctr = 0;
    my $strec;
    my $ipid = "";
    my $hdr;
    my $recx = 0;
    my $x;
    my $y;
    my $z;

    #print "$thisub : received arguments : @_\n";
    $srcf = shift(@_);
    print "$thisub :: trap source = $srcf\n";
    #if( $srcf =~ s/(\d{1,3}-\d{1,3}-\d{1,3}-\d{1,3})/)
    #  {
    #    $ipid = $1;
    #    print "$thisub :: IP ID for $srcf = $ipid\n";
    #  }
    $srch = open(IFH, "<", $srcf);
    if ( ! $srch )
       {
	print "$thisub :: error : unable to open src $srcf. returns : $!\n";
        return "";
       }	
    while( <IFH> )
      {
       $hdr = "";
       chomp $_;
       $_ =~ s/\s+$//;
       $line = $_;
       $lctr++;
       if($line =~ /^\d{4}-\d{2}-\d{2}/)
         {
          $hdr = "1";
	  $recx++;
	  if($line =~ /\[UDP:\s+\[(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})\]/ )
            {
	     $ipid = $1;
	     print "$thisub :: trap source = $ipid\n";
             if ( ! exists $TRAPOID{$ipid} )
	        {
		 $TRAPOID{$ipid} = {};
		}
	    }
         } # if header
       elsif (($line =~ /^\.iso\./ ) && ( exists $TRAPOID{$ipid} ))
         {
          print "$thisub :: notice : data record for $ipid : $line\n";
          @ax = split(/\t/,$line);
          foreach $x (@ax)
           {
            @ay = split(/=/, $x);
	    foreach $y (@ay)
	     {
              $ay[0] =~ s/^\s+//;
              $ay[0] =~ s/\s+$//;
              $ay[1] =~ s/^\s+//;
              $ay[1] =~ s/\s+$//;
	      if ( ! exists ${$TAPOID{$ipid}}{$ay[0]} )
                 {
                   ${$TRAPOID{$ipid}}{$ay[0]} = $ay[1];
	         }
	    } # foreach $y
	   } # foreach $x
	 } # elsif - if line data rec
      }
    close(IFH);

    return $retv;

  } # pulltrapinfo

sub  runddpunjtest
  {
   my $line;
   my $thisub = "runddpunjtest";
   my $testdev = shift;
   my $iplist = shift;
   my $testiF = shift;
   my $devcond = shift;
   my $testitle = shift;
   my $thisec;
   my $walkdest;
   my $walkdev;
   my $snmpcmd;
   
   print "test device = $testdev, ip list src = $iplist, test IF = $testiF, device condition = $devcond, test name = $testitle\n";

   open(IFH, "<", $iplist) or die ("not able to open $iplist, error = $!");

   while( <IFH> )
     {
       $line = $_;
       chomp($line);
       $line =~ s/\s+$//;
       #print "ip address = $line\n";
       $walkdev = $line;
       $walkdev =~ s/\./-/g;
       #print "walkdev = $walkdev\n";
       $thisec = `date +%Y%m%d_%H%M%S`;
       $thisec =~ s/\s+$//;
       $walkdest = "$den_snmp_dest_base"."/"."den_ddyadagiri_"."$testdev"."_"."$testiF"."_"."$walkdev"."_"."$testitle"."_"."$devcond"."_"."$thisec".".txt";
       $snmpcmd = "$snmpfx"." $line "."> ". "$walkdest";
       print "$snmpcmd\n";
       `$snmpcmd`;
     }
   close(IFH);
   #close(OFH);
   return;
  } # runddpunjtest 

sub pulltestrapoids
  {
    my $thisub = "pulltestrapoids";
    my $devoidh;
    my $srcf;
    my $srch;
    my $line;
    my @ax = ();
    my @ay = ();
    my @az =();
    my $flag = "";
    my $retv = "1";
    my $devoid = "";
    my $lctr = 0;
    my $strec;
    my $ipid = "";
    my $hdr = "";
    my $recx = 0;
    my $x;
    my $y;
    my $z;
    my $locts;
    my $isfdthere;
    my $hx;
    my $dsth,$dstx,$hy,$hz,$ostrx;

    #print "$thisub : received arguments : @_\n";
    #if( $srcf =~ s/(\d{1,3}-\d{1,3}-\d{1,3}-\d{1,3})/)
    #  {
    #    $ipid = $1;
    #    print "$thisub :: IP ID for $srcf = $ipid\n";
    #  }
    $srch = open(IFH, "<", $den_dev_snmptrapd_src);
    if ( ! $srch )
       {
        print "$thisub :: error : unable to open src $den_dev_snmptrapd_src. returns : $!\n";
        return "";
       }	
    while( <IFH> )
      {
       chomp $_;
       $_ =~ s/\s+$//;
       $line = $_;
       if($line =~ /^(\d{4}-\d{2}-\d{2}\s+\d{2}:\d{2}:\d{2})/)
         {
	  $locts = $1;
          $hdr = "1";
          if($line =~ /\[UDP:\s+\[(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})\]/ )
            {
	     $ipid = $1;
	     print "$thisub :: trap source = $ipid\n"; 
	    }
         } # if header
        elsif (($line =~ /^\.iso\./ ) && ( $hdr ))
         {
          print "$thisub :: notice : data record for $recx : $line\n";
          @ax = split(/\t/,$line);
          foreach $x (@ax)
           {
            @ay = split(/=/, $x);
	        $ay[0] =~ s/^\s+//; 
            $ay[0] =~ s/\s+$//;
            $ay[1] =~ s/^\s+//;
            $ay[1] =~ s/\s+$//;
            $isfdthere = istgtfdinoid($ay[0]);
            if(($isfdthere ) && ( ! exists $TRAPOID{$recx}))
              {
               $TRAPOID{$recx} = {};
               $devoidh = $TRAPOID{$recx};
               ${$devoidh}{"loc_ts"} = $locts;
               ${$devoidh}{"src_ip"} = $ipid;
               ${$devoidh}{"msg_bits"} = {}; 
	       $hx = ${$devoidh}{"msg_bits"};
	       ${$hx}{$isfdthere} = $ay[1];
               print "$thisub :: notice : created new record in global hash for rec # : $recx\n";
              }
	    elsif(( $isfdthere ) && ( exists $TRAPOID{$recx}))
	      {
               $hx = ${$devoidh}{"msg_bits"};
               ${$hx}{$isfdthere} = $ay[1];
               print "$thisub :: notice : added new field to message hash for rec # : $recx\n";
	      }
            elsif( ! $isfdthere )
              {
               print "$thisub :: warning : No valid pattern found in \"$ay[0]\"\n";
              }
           } # foreach $x
           $recx++;		   
         } # elsif - if line data rec
       $lctr++;
      } 
    close(IFH);
    
    $dstx = open(OFH, ">", $den_dev_snmptrap_dest);
    if ( ! $srch )
       {
        print "$thisub :: error : unable to open src $den_dev_snmptrap_dest. returns : $!\n";
        return "";
       }	
    foreach $recx ( sort { $a <=> $b } keys %TRAPOID )
     {
      $hx = $TRAPOID{$recx};
      $hy = ${$hx}{"msg_bits"};
      foreach $x ( sort keys %{$hy} )
       {
        $ostrx = "$recx"."$OFDLM"."${$hx}{\"src_ip\"}"."$OFDLM"."${$hx}{\"loc_ts\"}"."$OFDLM"."$x"."$OFDLM"."${$hy}{$x}";
	print OFH "$ostrx\n";
	print "$thisub :: final record : $ostrx\n";
       }
     }
    close(OFH);
    return $retv;
  } # pulltestrapoids

sub istgtfdinoid
  {
   my $thisub = "istgtfdinoid";
   my $oid = shift;
   my $rtv = "";
   my $x;
   
   foreach $x (@TGTOIDFIELDS)
    {
     if( $oid =~ /$x/ )
	   {
	     $rtv = $x;
		 print "$thisub :: found \"$x\" in \"$oid\"\n";
		 last;
	   }
	} #foreach
   if( ! $rtv )
    {
      print "$thisub :: warning : no target pattern found in \"$oid\"\n";
    }	  
   
   return $rtv;
  } # istgtfdinoid
