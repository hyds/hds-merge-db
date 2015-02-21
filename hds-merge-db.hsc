=setup
[Configuration]
ListFileExtension = HTM

[Window]
Name = HAS
Head = MergifyHy - Merge 2 or more Hydstra systems
Tail = Enter Parameters, <PgDn>:Execute, <F1>:Help, <F2>:Lookup, <Esc>:Abort.

[Labels]
CON     = END   2 10 Convert from DBF?
;DBFB    = END   +0 +1 DBF Folder for Base System
;DBFI    = END   +0 +1 DBF Folder for systems to be integrated
EXP     = END   +0 +1 HYCLIPIN Export Folder
OUT     = END   +0 +1 Report Output

[Fields] 
CON     = 3   10 INPUT   LIST        2  0  TRUE   0.0 0.0 'NO' YNO
;DBFB    = +0  +1 INPUT   CHAR       40  0  FALSE   FALSE  0.0 0.0 'C:\temp\merge\base' $PA
;DBFI    = +0  +1 INPUT   CHAR       40  0  FALSE   FALSE  0.0 0.0 'C:\temp\merge\integrate' $PA
EXP     = +0  +1 INPUT   CHAR       40  0  FALSE   FALSE  0.0 0.0 'C:\temp\export\' $PA
OUT     = +0  +1 INPUT   CHAR       20  0  FALSE   FALSE  0.0 0.0 'S' $OP

[Perl]


=cut


=head1 VERSION

Version 1.02

=cut

our $VERSION = '1.02';

=head1 SYNOPSIS

  This HYSCRIPT merges multiple systems into one system
 
  TODO:
  
  Add Default action - log and report any clashes.

=cut

use strict;
use warnings;
use DateTime;
use Env;
use File::Copy;
use Try::Tiny;

use FindBin qw($Bin $Script);

#Hydrological Administration Services Modules
use local::lib "$Bin";
use Export::SQLite;
use Export::dbf;
use Hydstra;
use Import;
use Import::fs;
use Import::ToSQLite;
use Import::Mergify;
use Import::Tables;

#use Hydstra::GetHeaders;
#use Logger;

#Hydstra libraries
require 'hydlib.pl';
require 'hydtim.pl';

my ( %variables_log, %ini );

main: {

  #Gather parameters and config
  my $script     = lc($Script);
  my $iniFile    = $script;
  $iniFile       =~ s{hsc$}{ini}i;
  $iniFile       = $Bin.'/'.$iniFile;
  
  Prt('-P',"inifile [$iniFile]");

  IniHash($ARGV[0],\%ini, 0, 0);
  IniHash($iniFile,\%ini, 0 ,0);
  
  my $fs = Import::fs->new();
  #Prt('-P',HashDump(\%ini));
  
  my $temp          = HyconfigValue('JUNKPATH').'mergify\\';
  my $csv_temp      = $temp.'csv\\';
  my $junk_db_dir   = $temp.'db\\';
  my $base_dir      = $temp.'csv\\base\\';
  
  my %source        = %{$ini{'source_tables'}};
  my $merge_tables  = $ini{'merge_tables'};
  my $convert_dbf   = $ini{perl_parameters}{con};
  #my $dbfb_dir      = $ini{perl_parameters}{dbfb};
  #my $integrate_dir = $ini{perl_parameters}{dbfi};
  my $export_dir    = $ini{perl_parameters}{exp};
  my $reportfile    = $ini{perl_parameters}{out};
  my $junk_db       = $junk_db_dir.NowString().'.db';
  
  MkDir($temp);
  MkDir($export_dir);
  MkDir($csv_temp);
  MkDir($junk_db_dir);
  
  #my $junk_db = $junk_db_dir.'20141201114424.db';
  
  # Get the tables for import form INI as hash
  my $im = Import::Tables->new(); 
  my %tables = $im->get_tables_hash({'merge_tables'=>$merge_tables});

  #export dbf to csv?
  if ( lc($convert_dbf) eq 'yes' ){
    foreach my $system ( keys %source){
      my $temp_dir = $csv_temp.$system.'\\';
      MkDir($temp_dir);
      my $sys_dir = $source{$system}.'\\';
      my @dbfs = $fs->FList($sys_dir,'dbf');
      foreach ( @dbfs ){
        #next if ( ! defined $ini{'merge_tables'}{lc(FileName($_))} );
        next if ( ! defined $tables{lc(FileName($_))} );
        my $exp = Export::dbf->new();
        $exp->export($_,$temp_dir); 
      }
    }  
  }
 
  Prt('-P',"Pause\n",HashDump(\%tables));
  # gwhole = { keys:[{fieldname:"hole",action:"increment",value:1}],subordinates:["gwpipe","hydmeas","hydrlmp","casing","aquifer","drilling"]}
  
  # Import base db csv files to SQLite.db
  my @base_files = $fs->FList($base_dir,'csv');
  my $imp = Import::ToSQLite->new({'temp' =>$temp,'db_file' =>$junk_db});
   
  # Import base files csv to SQLite - no merge required, just a straight import
  $imp->import_hydbutil_export_formatted_csv(\@base_files);
  
  # Get non-base db dir list
  opendir my($dh), $csv_temp or die "Couldn't open dir '$csv_temp': $!";
  my @source_dirs = grep { ! /^(\.\.?)$/ } readdir $dh;
  #my @source_dirs = grep { !/^(\.\.?|base)$/ } readdir $dh;
 
  
  #process VARIABLE tables if they exist
  my %var_sys_file;    
  foreach ( @source_dirs ){
    #collect variable tables
    my @sfiles = $fs->FList($csv_temp.$_,'variable.csv');
    $var_sys_file{$_} =  $sfiles[0];
  }  
  #Prt('-P',"var_sys_file [".HashDump(\%var_sys_file)."]\n");
  

  my $merge = Import::Mergify->new({'base_db_file'=>$junk_db});
  my $var_mappings = $merge->combine_variable_tables(\%var_sys_file);
  
  #Prt('-P',"var_mappings [".HashDump(\%{$var_mappings})."]\n");
  
  #import new variable table hash to sqlite db
  $imp->import_hash({'data'=>$var_mappings->{data},'module'=>'variable'});
  
  #merge
  foreach ( @source_dirs ){
    my $system = $_;
      
    #next if ( $_ !~ m{^(.*)l_hydx$}i);
    my $source_dir = $csv_temp.$_;
    my @src_files = $fs->FList($source_dir,'csv');
    
    #my $merge = Import::Mergify->new({'base_db_file'=>$junk_db});
    $merge->merge_hydbutil_export_formatted_csv({'source_files'=>\@src_files,'variable_mappings'=>$var_mappings->{mappings}});
  }
  

 # my $new_varno = $merge->lookup_new_varno(\%var_sys_file);
  
  my $exp = Export::SQLite->new({'temp'=>$temp,'db_file'=>$junk_db});
  $exp->to_hyclipin({'out'=>$export_dir});
  
  Prt("-P","systemfiles output to temp [$temp]"); #, reportfile [$reportfile], source [$source], base [$base]\n");
}


1; # End of Merge
