#!/usr/bin/perl

use strict;

my $HS = $ARGV[0];# 0:LP mode   1:HS mode
my $DT = $ARGV[1];# input DT:29 or 39

my $generic_long_packet_with_2byte = 0;


open FILE_IN , "<init_cfg.txt" or die $!;
my $o_name_num = 0;
my $o_name = "RegTable_PANEL$o_name_num.txt";
open my $FILE_OUT, ">$o_name" or die $!;

my $HS_COV = $HS;#HS mode:[31:0]->[24]
my $DT_COV = $DT;
my @tmp;
my $i;
my @data ;
my $j;
my $k;
my $data_in;
my $num;
my $num_mod;
my $less;
my $d0;
my $d0_dt;
my $num2_d1;
my $num2_d2;
my $num2_d2_dt;
my $num3_d0;
my $num2_d0_dt;
my $num3_d0_dt;
my $data_out;
my $num_less;
my $tmp;
my $num_less_end;
my @input_byte_data = {};
my $data_in_0A;
my $num_0A;
my $num_0A_mod;
my $less_0A;
my $num_less_0A;
my $num_less_end_0A;
my $addr = 0 ;
my $dsc_version_minor;
my $pic_height;  #PPS6[7:0],PPS7[7:0]
my $pic_width;   #PPS8[7:0],PPS9[7:0]
my $slice_height;#PPS10[7:0],PPS11[7:0]
my $slice_width; #PPS12[7:0],PPS13[7:0]
my $h_remainder;
my $w_remainder;
#---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
my $dirname = "./";  
opendir(DIR,$dirname) or die "open $dirname failed!";
while(my $file = readdir(DIR))
{
    if($file =~ /^RegTable_PANEL.*.bin$/)
    {
        my $full_path = "$file";
        unlink $full_path;#delete RegTable_PANEL*.bin
    }
}
#---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
while (<FILE_IN>)
{
    #$lines_num += 1;
    @tmp = split/\s+/,uc($_);
    $num = (length(@tmp[0])/2);
    #print "num:$num\n";
    $num_mod = $num % 8;
    #print "num_mod:$num_mod\n";
    $less = 8 - $num_mod;
    if($less != 8)
    {
        $data_in = @tmp[0].("00" x $less);
    }
    else{$data_in = @tmp[0]}
    $num_less = (length($data_in)/2);# Byte length after initial data zero padding
    $num_less_end = ($num_less / 8)*2;# Determine how many rows of data need to be generated

    #print "num_less_end:$num_less_end\n";
    #print "num_less:$num_less\n";
    #print "less:$less\n";
    #print "array:@tmp\n";
    #print "data_in:$data_in\n";
#---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    if($num == 1)
    {
        $d0 = substr @tmp[0], 0 , 2;
        if($d0 eq "11" || $d0 eq "29" || $d0 eq "28" || $d0 eq "10" )
        {
            $d0_dt = 05;
        }
        elsif($d0 eq "35" )
        {
            $d0_dt = 15;
        }
        else 
        {
             $d0_dt = 03;
        }    
        printf $FILE_OUT "0$HS_COV"."00%02s%02s\n",$d0,$d0_dt;
        $addr += 4;
    }
#---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    elsif($num == 2)
    {
        $num2_d1 = substr @tmp[0], 0 , 2;
        $num2_d2 = substr @tmp[0], 2 , 2;
        if($num2_d1 eq "35" || $num2_d1 eq "53" || $num2_d1 eq "51" )
        {
            $num2_d0_dt = 15;
            printf $FILE_OUT "0$HS_COV"."%02s%02s%02s\n",$num2_d2,$num2_d1,$num2_d0_dt;
            $addr += 4;
        }
        elsif ($generic_long_packet_with_2byte == 1)
        {
            #$num3_d0_dt = 29;
            printf $FILE_OUT "0$HS_COV"."%04X%02D\n",$num,$DT_COV;
            $addr += 4;
            for($j = 0;$j<$num_less;$j++)
            {
                $input_byte_data[$j] = substr($data_in,$j*2,2);
            }

            for($j = 0;$j<$num_less_end;$j++)
            {
                printf $FILE_OUT "%s\n",$input_byte_data[3 + $j*4].$input_byte_data[2 + $j*4].$input_byte_data[1 + $j*4].$input_byte_data[0 + $j*4];
                $addr += 4;
            }

        }
        else
        {
            $num2_d0_dt = 23;
            printf $FILE_OUT "0$HS_COV"."%02s%02s%02s\n",$num2_d2,$num2_d1,$num2_d0_dt;
            $addr += 4;
        }

    }
#---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    elsif($num >2)
    {
        $num3_d0 = substr @tmp[0], 0 , 2;
#---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
        if($num3_d0 eq "0A")
        {   
            $num_0A = (length(substr(@tmp[0],2))/2);
            $num_0A_mod = $num_0A % 8;
            $less_0A = 8- $num_0A_mod;
            $dsc_version_minor = substr (@tmp[0],2,2);
            $pic_height = hex(substr @tmp[0], 14 , 4);
            $pic_width = hex(substr @tmp[0], 18 , 4);
            $slice_height = hex(substr @tmp[0], 22 , 4);
            $slice_width = hex(substr @tmp[0], 26 , 4);
            #print "tmp:@tmp[0]\n";
            #print "num_0A:$num_0A\ndsc_version_minor:$dsc_version_minor\npic_height:$pic_height\npic_width:$pic_width\nslice_height:$slice_height\nslice_width:$slice_width\n";
            #print "num_0A:$num_0A\nnum_0A_mod:$num_0A_mod\nless_0A:$less_0A\n";
            if( ($num_0A >= 88) && (($dsc_version_minor eq "11") || ($dsc_version_minor eq "12")) )
            {
                $h_remainder = $pic_height % $slice_height;
                $w_remainder = $pic_width % $slice_width;
                #print "num_0A:$num_0A\n";
                if(($h_remainder == 0) && ($w_remainder == 0))
                {
                    if($less_0A != 8)
                    {
                        $data_in_0A = substr(@tmp[0],2).("00" x $less_0A);
                    }
                    else{$data_in_0A = substr(@tmp[0],2)}

                    #print "data_in_0A:$data_in_0A\n";
    
                    $num_less_0A = (length($data_in_0A)/2);
                    $num_less_end_0A = ($num_less_0A / 8)*2;

                    $num3_d0_dt = "0A";
                    printf $FILE_OUT "0$HS_COV"."%04X%02s\n",$num-1,$num3_d0_dt;
                    $addr += 4;

                    for($j = 0;$j<$num_less_0A;$j++)
                    {
                        $input_byte_data[$j] = substr($data_in_0A,$j*2,2);
                    }
                    for($j = 0;$j<$num_less_end_0A;$j++)
                    {
                        printf $FILE_OUT "%s\n",$input_byte_data[3 + $j*4].$input_byte_data[2 + $j*4].$input_byte_data[1 + $j*4].$input_byte_data[0 + $j*4];
                        $addr += 4;
                    }
                }
            }
            else
            {
                #$num3_d0_dt = 29;
                printf $FILE_OUT "0$HS_COV"."%04X%02D\n",$num,$DT_COV;
                $addr += 4;
                for($j = 0;$j<$num_less;$j++)
                {
                    $input_byte_data[$j] = substr($data_in,$j*2,2);
                }

                for($j = 0;$j<$num_less_end;$j++)
                {
                    printf $FILE_OUT "%s\n",$input_byte_data[3 + $j*4].$input_byte_data[2 + $j*4].$input_byte_data[1 + $j*4].$input_byte_data[0 + $j*4];
                    $addr += 4;
                }
            }
        }
#---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
        elsif($num3_d0 eq "2A" || $num3_d0 eq "2B" || $num3_d0 eq "51")
        {
            #$num3_d0_dt = 39;
            printf $FILE_OUT "0$HS_COV"."%04X%02D\n",$num,$DT_COV;
            $addr += 4;
            for($j = 0;$j<$num_less;$j++)
            {
                $input_byte_data[$j] = substr($data_in,$j*2,2);
            }

            for($j = 0;$j<$num_less_end;$j++)
            {
                printf $FILE_OUT "%s\n",$input_byte_data[3 + $j*4].$input_byte_data[2 + $j*4].$input_byte_data[1 + $j*4].$input_byte_data[0 + $j*4];
                $addr += 4;
            }
        }
#---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
        else
        {
            #$num3_d0_dt = 29;
            printf $FILE_OUT "0$HS_COV"."%04X%02D\n",$num,$DT_COV;
            $addr += 4;
            for($j = 0;$j<$num_less;$j++)
            {
                $input_byte_data[$j] = substr($data_in,$j*2,2);
            }

            for($j = 0;$j<$num_less_end;$j++)
            {
                printf $FILE_OUT "%s\n",$input_byte_data[3 + $j*4].$input_byte_data[2 + $j*4].$input_byte_data[1 + $j*4].$input_byte_data[0 + $j*4];
                $addr += 4;
            }

        }

        #print $addr."\n";
    }
    #print $addr."\n";
#---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------    
    if($addr >= 15000)
    {
        close($FILE_OUT);
        $addr = 0;
        $o_name_num++;
        $o_name = "RegTable_PANEL$o_name_num.txt";
        open $FILE_OUT, ">$o_name" or die $!;
    }
#---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------    
}
#my $lines_num = ($addr / 4);
#print "lines_num:$lines_num\n";
close(FILE_IN); 
close($FILE_OUT); 

#system "perl -p -i -e 's/REGTABLE_ENTRYNUM = 0/REGTABLE_ENTRYNUM = $lines_num/' $ofile";
