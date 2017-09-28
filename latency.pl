#!/usr/bin/perl
use Image::Magick;
use String::Scanf; #

my $num_args;
$num_args = $#ARGV + 1;
printf("arg- $num_args\n");
if ($num_args == 0) {
	$nn=100;    
}
else
{
$nn=$ARGV[0];
}

my($image, $image1, $image2, $p, $q, $res, $mean, $nmean, $mmax, $mmin);
# run gimp on frame003.png and select the subimage read on tool option
my $box1='324x79+156+128';
my $box2='314x79+936+125';

#initialized to a big value
$mmin=100;

$image = new Image::Magick;
system(" rm *.png");
system(" gst-launch-1.0 v4l2src num-buffers=$nn !  pngenc !  multifilesink  location=\"frame%03d.png\"");

$image->Read('frame*.png');
#$image->Contrast();

sub ocr_out_mod {
	my $x = shift(@_);
	$x =~ s/\W//g;
	#printf("-> $x \n");
	#try to detect and fix : interpreted as 1
	if (length($x)>9) {
		my $xx;
		$xx =~ s/1//g;
		$x=$xx if (length($xx)==9);
	  #$x=substr($x,0,6).substr($x,8);
	  #printf(">> $x \n");
    }	
    #printf("$x \n");
    if (length($x)==9) {
    	$x=substr($x,0,2). ":" . substr($x,2,2). ":"  . substr($x,4,2).":".substr($x,6,3);
	}
	else
	{
		$x=substr($x,0,2). ":" . substr($x,2,2). ":"  . substr($x,4,2).":".substr($x,-3);
	}
	printf(">> $x \n");
	return $x;
}
# first image is in general not good
for ($x = 1; $image->[$x]; $x++)
{ 
  #printf("image %03d\n",$x);
  #$res=sprintf("convert frame%03d.png -threshold %30 frame_%03d.png",$x,$x);
  #system($res);
  #$image->[$x]->Quantize(colorspace=>'');
  $image->[$x]->Threshold(threshold=>"40%");
  $image->[$x]->Negate(channel=>'All');
  
  $image1 = $image->[$x]->Clone();
  $image1->Crop(geometry=>$box1);
  $res=sprintf("frame_%03d_1.png",$x);
  $image1->Write($res);
  $out=`../build/bin/tesseract  -psm 7 $res - digits`;
  $out=ocr_out_mod($out);
  #printf("$out\n");
  ($h, $m, $s, $d) = sscanf("%d:%d:%d:%03d", $out);
  
  $image2 = $image->[$x]->Clone();
  $image2->Crop(geometry=>$box2);
  $res=sprintf("frame_%03d_2.png",$x);
  $image2->Write($res);
  $out=`../build/bin/tesseract  -psm 8 $res - digits`;
  $out=ocr_out_mod($out);
  #printf("$out\n");
  ($hh, $mm, $ss, $dd) = sscanf("%d:%d:%d:%03d", $out);

  
  $x1=$h*3600+$m*60+$s+$d/1000.0;
  $x2=$hh*3600+$mm*60+$ss+$dd/1000.0;
  $xx=$x1-$x2;
  #printf("lat: %f %f => %f\n",$x1,$x2,$xx);
  #tolerance for logical variable 10ms:600ms
  if ($xx>0.01&&$xx<0.6) 
  {
  	printf("[%03d] - lat: %f\n",$x,$xx);
  	$mean+=$xx;
  	$nmean++;
  	$mmax=$xx if ($xx>$mmax);
  	$mmin=$xx if ($xx<$mmin);
  }
}

if ($nmean>0) {
	printf("AVG latency: %f %d:[min: %f max: %f]\n",$mean/$nmean,$nmean,$mmin,$mmax);
}
else {
printf("Error in ocr reading counter -  no item successfully read !\n");
}
