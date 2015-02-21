# Version

Version 0.02

# Synopsis

This HYSCRIPT aims to merge two or more large Hydstra(TM) systems into one system. Typically you should not perform the merge task on a production system, but rather on a copy of that system

Mergify-hy assumes that when merging two or more Hydstra systems, you will want to keep one of the systems intact. This is called the "base system". 

If there are clashes in the keys and values of records between the base system and another system, the base system will not be modified. Therefore the other source systems will need to be modified in some way to retain the record, but not overwrite the base system.

The script also assumes that you are using potentially large tables, like WQ tables, with millions of rows, and so it caches data in a provisional, dated SQLite database.

When running the script make sure that you do a manual sanity/quality assurance check that the output tables are valid before making them your production data.

# Procedure

1. Copy DBF paths of all the systems to a safe location
2. Identify the base system folder in the [source_tables] section of the INI configuration file
3. Idenfify the non-base systems folder in the [source_tables] section of the INI configuration file
4. Specify which tables to merge in the [merge_tables]
5. Run script 
6. Use HYCLIPIN to import the resulting tables to a work area
7. Perform a quality/sanity check on the data 

## Parameter screen

As noted above, the systems and tables you want to merge are configured in the INI file.

You may have already converted the DBF files to 

![Parameter screen](/images/psc.PNG)

## INI configuration

In the INI config file you can select a few of the DBF files for merging from your copy of DBFPATH. 

You MUST have a 'base' system which is the one that will be the starting point to which others are compared. All other subsection names are arbitrary except for the 'base' subsection name which has a fixed meaning so be careful. The base system will not be changed, whilst others may be if they clash with the base system

![INI file](/images/ini.png)

## Script process

The basic process that the script steps through is:

1. DBF Conversion to CSV (if selected, otherwise assuem CSVs are there)
2. Import base system to temp SQLite.db
3. Import non-base systems to temp SQLite.db and handle clashes
4. Export a merged system from the temp SQLite.db to HYCLIPIN files
5. Manually import the HYCLIPIN files to your final system

## Clashes

Clash handling is detailed in the table below. Usually there are complex business rules for naming a site. These differ 
between businesses and between projects. Due to this variabiliyt, no automation has been implemented and checking for clashes will need to be done manually. So the SITE table itself is assumed to have no clashes.

* If there is a site number in a non-base system (which is not a clash) it will be imported to the base system

 
|	TABLE	|	HANDLING TYPE	|	CLASH HANDLING	| IMPLEMENTED 	|
|-----------|-------------------|-------------------|---------------|
|	SITE 	|	 Manual			|					|				|
|   STATION	|	 Manual			|					|				|
|	    STNINIKW 	|	Auto	|	 Append, On clash append '_systemID' (handled before SNINI and changes pushed to STNINI)	|	no			|
|	    STNINI 	|	Auto	|	 increment STNINI.ORDER by 1	| no				|
|	    BENCH 	|	Auto	|	 increment BENCH.BENCH by 1	|	no			|
|	    HISTORY 	|	Auto	|	 increment HISTORY.STATTIME by 1	|	no			|
|	    PERIOD 	|	 Calculated table, leave	|	n/a	|				|
|	    INSTHIST 	|	 Manual	|		|	n/a			|
|	    SERIES 	|	 Calculated table, leave 	|		|	n/a			|
|	    PEAKTIME 	|	 Calculated table, leave 	|		|	n/a			|
|	    RATEPER 	|	 Manual	|		|	n/a			|
|	    RATEHED 	|	 Manual	|		|	n/a			|
|	    RATEPTS 	|	 Manual	|		|	n/a			|
|	    RATEEQN 	|	 Manual	|		|	n/a			|
|	    TTABHED 	|	 Manual	|		|	n/a			|
|	    TTABPTS 	|	 Manual	|		|	n/a			|
|	    SSHIFT 	|	 Manual	|		|		n/a		|
|	    TSHIFT 	|	 Manual	|		|		n/a		|
|	    GAUGINGS 	|	 Manual	|		|	n/a			|
|	    GAUGMEAS 	|	 Manual	|		|	n/a			|
|	    SECTHED 	|	 Manual	|		|	n/a			|
|	    SECTIONS 	|	 Manual	|		|	n/a			|
|	    SECTSURV 	|	 Manual	|		|	n/a			|
|	    NRSTN 	|	 Manual	|		|	n/a			|
|	    VRWEWA 	|	 Manual	|		|	n/a			|
|	    VRWMON 	|	 Manual	|		|	n/a			|
|	    VARIABLE	|	 Auto	|	non-base system variable number will increment by 1 to the next available free number in the base system variable table	|	yes			|
|	    SAMPLES	|	 Auto	|	non-base system SAMPLES.SAMPLENO increment by 1	|	yes			|
|	    RESULTS	|	 Auto	|	non-base system RESULTS.SAMPLENO increment by 1	|	yes			|


### Clashes in GW tables NOT IMPLEMENTED

* The base system will be preserved and non-base system 

## Dependencies

In order to store data in SQL tables Hydstra tables have been defined in other modules using OO Perl. hence it has dependencies, all of which can be downloaded from GitHub

* Hydstra
* ToSQLite
* Mergify
* fs
* import
* export
 
## Bugs

Please report any bugs in the issues wiki.

