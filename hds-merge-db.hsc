=setup

[Configuration]
ListFileExtension = TXT

[Window]
Name = HAS
Head = MergifyHy - Merge 2 or more Hydstra systems


[Labels]
EXP     = END   2 10 Export Folder
OUT     = END   +0 +1 Report Output

[Fields] 
EXP     = 3   10 INPUT   CHAR       40  0  FALSE   FALSE  0.0 0.0 'C:\temp\mergify_export\' $PA
OUT     = +0  +1 INPUT   CHAR       20  0  FALSE   FALSE  0.0 0.0 'S' $OP

[Perl]



=cut


=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

  This HYSCRIPT merges multiple systems into one system
  
  Things to check
  1. is this the same name as any other variable
  2. yes? then change the source system var no to the base varno and keep a log of this for the system
  3. is the same varno, and almost hte same name? ( then just use the base var and skip)
  4. is the same varno but a different name? (then search for a free one, and keep a log of all the variables so you don't overwrite)
  5. also keep a log of the system and the varno mapping so that the results can map the variable when encourntered.
  
  Procedure:
  1. Open all variable tables for the base system
  2. create a hash of the tables2. create hashes of the source system tables
  2.1 fuzzy match the first few characters, and the units, and the Hydstra units
  2.2 if there is a variable fuzzy match then 
  3. if the variable is registered find the next available
  4. Log all the new variables
  4.1 save to the variable sql
  5. hash log of the system, and the variable mapping for that system
  6. 
  6.1 open all tables in 

=cut

use strict;
use warnings;
use DateTime;
use Env;
use File::Copy;
use Try::Tiny;

use FindBin qw($Bin);

#Hydrological Administration Services Modules
use local::lib "$Bin/HDS/";
use Export::SQLite;
use Export::dbf;
use Hydstra;
use Import;
use Import::fs;
use Import::ToSQLite;
use Import::Mergify;

#use Hydstra::GetHeaders;
#use Logger;

#Hydstra libraries
require 'hydlib.pl';
require 'hydtim.pl';

my (%variables_log,%ini);

main: {

  #Gather parameters and config
  my $script     = lc(FileName($0));
  IniHash($ARGV[0],\%ini, 0, 0);
  IniHash($script.'.ini',\%ini, 0 ,0);
  
  my $fs = Import::fs->new();
  #Prt('-P',HashDump(\%ini));
  
  my $temp          = HyconfigValue('JUNKPATH').'mergify\\';
  my $csv_temp      = $temp.'csv\\';
  my $junk_db_dir   = $temp.'db\\';
  my $base_dir      = $temp.'csv\\base\\';
  
  my %source        = %{$ini{'source_tables'}};
  my $export_dir    = $ini{perl_parameters}{exp};
  my $reportfile    = $ini{perl_parameters}{out};
  my $junk_db       = $junk_db_dir.NowString().'.db';
  
  MkDir($temp);
  MkDir($export_dir);
  MkDir($csv_temp);
  MkDir($junk_db_dir);
  
  my $junk_db = $junk_db_dir.'20141201114424.db';
  
=skip  

  #export dbf to csv
  foreach my $system ( keys %source){
    my $temp_dir = $csv_temp.$system.'\\';
    MkDir($temp_dir);
    my $sys_dir = $source{$system}.'\\';
    my @dbfs = $fs->FList($sys_dir,'dbf');
    foreach ( @dbfs){
      next if ( ! defined $ini{'merge_tables'}{lc(FileName($_))} );
      my $exp = Export::dbf->new();
      $exp->export($_,$temp_dir); 
    }
  }  
 
=cut
  
  #import base db csv files to SQLite.db
  my @base_files = $fs->FList($base_dir,'csv');
  my $imp = Import::ToSQLite->new({'temp' =>$temp,'db_file' =>$junk_db});
   
  #Uncomment to import to csv
  $imp->import_hydbutil_export_formatted_csv(\@base_files);
  
  #get non-base file lists
  opendir my($dh), $csv_temp or die "Couldn't open dir '$csv_temp': $!";
  my @source_dirs = grep { ! /^(\.\.?)$/ } readdir $dh;
  #my @source_dirs = grep { !/^(\.\.?|base)$/ } readdir $dh;
 
  #Prt('-P',"Source_dirs [".HashDump(\@source_dirs)."]");
  
  
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
    #Prt('-P',"source DIRS [$source_dir] [$_], junk_db [$junk_db] HashDump \n[".HashDump(\@src_files)."]\n");
    
    #my $merge = Import::Mergify->new({'base_db_file'=>$junk_db});
    $merge->merge_hydbutil_export_formatted_csv({'source_files'=>\@src_files,'variable_mappings'=>$var_mappings->{mappings}});
  }
  

  
 # my $new_varno = $merge->lookup_new_varno(\%var_sys_file);
  
  
  
  #Prt('-P',"Variable Mapping Returned from combine variable tables [".HashDump(\%var_mappings)."]\n");
  #Now that we have the merged variable table 
  #2. fix up the remaining variable tables using the mappings hash
  #3. merge the samples tables
  #4. map the results tables
  #5. merge the results tables.
  #6. Export to HYCLIPIN file format
  my $exp = Export::SQLite->new({'temp'=>$temp,'db_file'=>$junk_db});
  $exp->to_hyclipin({'out'=>$export_dir});
  
 
  #Prt('-P',"systemfiles \n[".HashDump(\%var_sys_file)."]\n");
  Prt('-R',"systemfiles\n");
  
  
  
  #$compbined_variables{};
  #$system_variable_mapping{$system}{$variable} = $variable_mapping;
  #$system_variable_mapping{vic_citrix}{1110} = 1112;
  
  
  
=skip    
  Prt('-P',"source_dirs\n".HashDump(\@source_dirs));
  #Prt('-P',"dir handle [$source]\n");
  my @source_files = DOSFList($source,1); # $fs->FList(@source_dirs,'*.csv');
  
  #Prt('-P',"base_files\n".HashDump(\@base_files));
  #Prt('-P',"source_files\n[".HashDump(\@source_files)."]");
=cut  
  Prt("-P","temp [$temp]"); #, reportfile [$reportfile], source [$source], base [$base]\n");

  
}


1; # End of Merge
