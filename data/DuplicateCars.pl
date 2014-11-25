#!/usr/bin/perl -w
use DBI;
use strict;


use FileHandle;

@ARGV == 1 or die ("Usage: perl DuplicateCars.pl [PROPERTIES FILE]");

# this goes into files file

my $currLine;
my @currProp;
my $propertyfile=$ARGV[0];;
my $cardatapoints="cardatapoints.out";
my $logvar="no";
my $dbname="test1";
my $dbuser="linear";
my $dbpassword="linear";
my $logfile="execution.log";
my $numberOfExpressways=2;
my $overlap=10;
my @numberOfCars;
my @numberOfQid;
my $dir="/home/linear/data1";

open( PROPERTIES , "$propertyfile") || die("Could not open file: $!");


#******************** Import properties
open( PROPERTIES , "$propertyfile") || die("Could not open file: $!");
while (  $currLine = <PROPERTIES>){
  chomp ( $currLine );
  @currProp=split( /=/, $currLine  );
  if ( $currProp[0] eq "cardatapointst") {
    $cardatapoints=$currProp[1];
  }
  if ( $currProp[0] eq "keeplog") {
    $logvar=$currProp[1];
  }
  if ( $currProp[0] eq "databasename") {
    $dbname=$currProp[1];
  }	
  if ( $currProp[0] eq "databaseusername") {
    $dbuser=$currProp[1];
  }
  if ( $currProp[0] eq "databasepassword") {
    $dbpassword=$currProp[1];
  }
  if ( $currProp[0] eq "directoryforoutput") {
    $dir=$currProp[1];
  }
  if ( $currProp[0] eq "numberofexpressways"){
    $numberOfExpressways=$currProp[1];
  }
}



close ( PROPERTIES );

my $dbquery;
my $sth;    
writeToLog ( $logfile, $logvar, "Connecting to DB");
my $dbh = DBI->connect("DBI:PgPP:$dbname", $dbuser, $dbpassword)
  or die "Couldn't connect to database: ". DBI->errstr;


# Create input table in db and import
writeToLog ( $logfile, $logvar, "Creating input table.");
$dbquery="DROP TABLE IF EXISTS input; CREATE TABLE input ( type integer, time integer, carid integer, speed integer, xway integer, lane integer, dir integer, seg integer, pos integer, qid integer, m_init integer, m_end integer, dow integer, tod integer, day integer );";
$sth=$dbh->prepare("$dbquery") or die $DBI::errstr;
$sth->execute;


#Full expressway Loop (generates an extra one for half).
for( my $x=0; $x < $numberOfExpressways; $x++){
  # run linear road
  writeToLog ( $logfile, $logvar, "Linear road run number: $x");
  system ("perl linear-road.pl --dir=$dir");
  rename( $dir."/cardatapoints.out.debug" , $dir."/cardatapoints$x.out.debug" );

#	Get max carid to use in offset or if its the last loop to use for random generator
  writeToLog ( $logfile, $logvar, "Querying max carid for next offset.");
  $dbquery="SELECT max(carid), max(qid) FROM input;";
  $sth=$dbh->prepare("$dbquery") or die $DBI::errstr;
  $sth->execute;
  @numberOfCars = $sth->fetchrow_array;
  writeToLog ( $logfile, $logvar, "numberOfCars value: ".join(",", @numberOfCars));

#	On all but first xway need to update xway number and adjust carids
  if ($x!=0){
    writeToLog ( $logfile, $logvar, "Updating current xway to xway=$x.");
    $dbquery="UPDATE input SET xway=".$x.", carid=carid+".$numberOfCars[0].", qid=qid+".$numberOfCars[1]." WHERE xway=0;";
    $sth=$dbh->prepare("$dbquery") or die $DBI::errstr;
    $sth->execute;	
  }
  writeToLog ( $logfile, $logvar, "Generating history.");
  #rename( $dir."/cardatapoints.out$x" , $dir."/$cardatapoints" );
  writeToLog ( $logfile, $logvar, "Importing cardatapoints $x into input table.");	
  $dbquery="COPY input FROM '".$dir."/$cardatapoints' USING DELIMITERS ','";
  $sth=$dbh->prepare("$dbquery") or die $DBI::errstr;
  $sth->execute;

  rename( $dir."/$cardatapoints" , $dir."/$cardatapoints$x" );
}
$dbquery="SELECT max(carid), max(qid) FROM input;";
$sth=$dbh->prepare("$dbquery") or die $DBI::errstr;
$sth->execute;
@numberOfCars = $sth->fetchrow_array;
writeToLog ( $logfile, $logvar, "numberOfCars value 2: ".join(",", @numberOfCars));

writeToLog ( $logfile, $logvar, "Generating history.");
system("perl historical-tolls.pl $numberOfExpressways $numberOfCars[0] $dir");

#create indexes on carid, time...this step maybe not be worth it
writeToLog ( $logfile, $logvar, "Adding indexes on input (carid), (carid, time), (time).");
$dbquery="CREATE INDEX inputcarid ON input (carid);CREATE INDEX inputcaridtime ON input (carid, time);CREATE INDEX inputtime ON input (time);";
$sth=$dbh->prepare("$dbquery") or die $DBI::errstr;
$sth->execute;


#Half expressway--just delete half from the full run if there is a half
if (int $numberOfExpressways != $numberOfExpressways){
  writeToLog ( $logfile, $logvar, "Adjusting datapoints for half of expressway.");
  $dbquery="DELETE FROM input WHERE xway=0 and dir=0;";
  $sth=$dbh->prepare("$dbquery") or die $DBI::errstr;
  $sth->execute;
}



#Writing maxCarid into a file
open(CAROUT, ">".$dir."/maxCarid.out") || die("Could not open file: $!");
print CAROUT ($numberOfCars[0] );
close(CAROUT);


#Generating random cars that will be duplicates into duplicatecars table
writeToLog ( $logfile, $logvar, "Generating random carids for duplication.");
$dbquery="CREATE TABLE duplicatecars (carid integer);";
$sth=$dbh->prepare("$dbquery") or die $DBI::errstr;
$sth->execute;
generateRandomTable ($numberOfCars[0], $overlap, $dbh);

#Join input with duplicatecars table to get enter and exit times
writeToLog ( $logfile, $logvar, "Getting enter xway and exit xway times for each car to duplicate into carsandtimes.");
$dbquery="SELECT duplicateCars.carid, min(input.time) as entertime, max (input.time) as leavetime INTO carsandtimes FROM duplicateCars, input WHERE duplicateCars.carid=input.carid GROUP by duplicatecars.carid;";
$sth=$dbh->prepare("$dbquery") or die $DBI::errstr;
$sth->execute;

writeToLog ( $logfile, $logvar, "Creating indexes on carsandtimes table.");

$dbquery="CREATE INDEX carsandtimescarid ON carsandtimes (carid);CREATE INDEX carsandtimescaridenter ON carsandtimes (carid, entertime);CREATE INDEX carsandtimescaridleave ON carsandtimes (carid, leavetime);";
$sth=$dbh->prepare("$dbquery") or die $DBI::errstr;
$sth->execute;

writeToLog ( $logfile, $logvar, "Generate table with matched up replacements.");
$dbquery="CREATE TABLE carstoreplace (carid integer, cartoreplace integer);";
$sth=$dbh->prepare("$dbquery") or die $DBI::errstr;
$sth->execute;

writeToLog ( $logfile, $logvar, "Getting first disjoing match.");
$dbquery="	SELECT times.carid, times.entertime, times.leavetime, times_1.carid as carid1, times_1.entertime as entertime1, times_1.leavetime as leavetime1
FROM carsandtimes as times, carsandtimes AS times_1
WHERE times_1.entertime>times.leavetime+ 1000*random()+61
LIMIT 1;";
$sth=$dbh->prepare("$dbquery") or die $DBI::errstr;
$sth->execute;		

my $replacements=0;
my @carReplacement;



while (@carReplacement = $sth->fetchrow_array){

#	$dbquery="UPDATE input SET carid=".$carReplacement[3]."WHERE carid=".$carReplacement[0].";";
#	$sth=$dbh->prepare("$dbquery") or die $DBI::errstr;
#	$sth->execute;	

  $dbquery="INSERT INTO carstoreplace VALUES (".$carReplacement[0].",".$carReplacement[3].");";
  $sth=$dbh->prepare("$dbquery") or die $DBI::errstr;
  $sth->execute;	

  $dbquery="DELETE FROM carsandtimes WHERE carid=".$carReplacement[3]."OR carid=".$carReplacement[0].";";
  $sth=$dbh->prepare("$dbquery") or die $DBI::errstr;
  $sth->execute;	

  $replacements++;
  #writeToLog ( $logfile, $logvar, "Replacing $carReplacement[0] with $carReplacement[3].");
  $dbquery="	SELECT times.carid, times.entertime, times.leavetime, times_1.carid as carid1, times_1.entertime as entertime1, times_1.leavetime as leavetime1
  FROM carsandtimes as times, carsandtimes AS times_1
  WHERE times_1.entertime>times.leavetime+ 1000*random()+61
  LIMIT 1;";
  $sth=$dbh->prepare("$dbquery") or die $DBI::errstr;
  $sth->execute;	
}
writeToLog ( $logfile, $logvar, "Replace carids with generated duplicates.");
$dbquery="UPDATE input SET carid=carstoreplace.carid FROM carstoreplace WHERE input.carid=carstoreplace.cartoreplace;";
$sth=$dbh->prepare("$dbquery") or die $DBI::errstr;
$sth->execute;	

writeToLog ( $logfile, $logvar, "Droppig all tables.");
$dbquery="DROP TABLE carstoreplace; DROP TABLE carsandtimes; DROP TABLE duplicatecars;";
$sth=$dbh->prepare("$dbquery") or die $DBI::errstr;
$sth->execute;	

# Need paths.	
writeToLog ( $logfile, $logvar, "Exporting out to a file.");
$dbquery="copy input to '".$dir."/cardatapoints.out' using delimiters ','";
$sth=$dbh->prepare("$dbquery") or die $DBI::errstr;
$sth->execute;	

writeToLog ( $logfile, $logvar, "If no error message generated, cardatapoints.out and other linear-road output should be stored in $dir.");
writeToLog ( $logfile, $logvar, "If there was an error and cardatapoints.out was not extracted correctly, it is stored in database $dbname. Table name is input. It should be extracted manually to cardatapoints.out file");

$dbh->disconnect;

sub generateRandomTable {
  my( $projectedCarTotal, $overlap, $dbconnection) = @_;
  my $dbquery;
  my $sth;  

  for( my $i=100; $i<$projectedCarTotal; $i++ ){
    if( rand(100) < $overlap){
      $dbquery="INSERT INTO duplicateCars VALUES ($i);";
      $sth=$dbh->prepare("$dbquery") or die $DBI::errstr;
      $sth->execute;
    }
  }
}

sub logTime {
  my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)=localtime(time);
  return ( ($mon+1)."-".$mday."-".($year+1900)." ".$hour.":".$min.":".$sec );
}

sub writeToLog {
  my ( $logfile, $logvar, $logmessage ) = @_;
  if ($logvar eq "yes") {
    open( LOGFILE1, ">>$logfile")  || die("Could not open file: $!");
    LOGFILE1->autoflush(1);
    print LOGFILE1 ( logTime()."> $logmessage"."\n");
    close (LOGFILE1);
  }
  else {
    print ( logTime()."> $logmessage"."\n");
  }
}
