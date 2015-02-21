# Version

Version 0.02

# Synopsis

This HYSCRIPT aims to merge two or more large Hydstra(TM) systems into one system. Typically you should not perform the merge task on a production system, but rather on a copy of that system

Mergify-hy assumes that when merging two or more Hydstra systems, you will want to keep one of the systems intact. This is called the "base system". 

If there are clashes in the keys and values of records between the base system and another system, the base system will not be modified. Therefore the other source systems will need to be modified in some way to retain the record, but not overwrite the base system.

The script also assumes that you are using potentially large tables, like WQ tables, with millions of rows, and so it caches data in a provisional, dated SQLite database.

When running the script make sure that you do a manual sanity/quality assurance check that the output tables are valid before making them your production data.

# Time series files 

Since Hydstra has binary files for timeseries, it is assumed that the user has already handled them with Hydstra TS management tools and no merge is required. See HYDBUTIL, HYDMWB etc.

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

### Default
If you specify a table = 1, you will get the default action which is to simply report on clash

``` ini

site = 1 
results = 1
samples = 1

```

### Actions
You can specify a set of finite actions that you want the script to perform when it finds a clash. Action options are increment, decrement, append, prepend.
The actions are essentially your business rules. 

In the example below SAMPNUM will be increment by one for the RESULTS table

``` ini

results = {keys:{field:"sampnum",action:"increment",value:1},subordinates:null}

```

If you wanted to append some text such as "_merge" to the RESULTS.SAMPNUM field instead of incrementing by 1 you would have the following:

``` ini

results = {keys:{field:"sampnum",action:"append",value:"_merge"},subordinates:null}

```

If you wanted to change two key fields for some reason you could specify it like this:


``` ini

gwpipe = {keys:[{field:"hole",action:"increment",value:1},{field:"pipe",action:"increment",value:1}],subordinates:null}

```

### Orphans

For the example above, we will have changed the results table with no respect for the samples table. 
So we have potentially just created orphan records.
To take care of orphans can simply say that the results table was subordinate to the samples table.
This way, any changes to SAMPLES.SAMPNUM will cascade down to the RESULTS table
We could specify such like so:

``` ini

samples = {keys:[{fieldname:"sampnum",action:"increment",value:1}],subordinates:["results"]}

```

If this was a groundwater table like GWHOLE you might want to increment the HOLE field by one and cascade this down to all subordinate tables, and you would do such thus:

``` ini

gwhole = {keys:[{fieldname:"hole",action:"increment",value:1}],subordinates:["gwpipe","hydmeas","hydrlmp","casing","aquifer","drilling"]}

```

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
|	SITE 	|	 Manual			|	Default			|	no			|
|   STATION	|	 Manual			|	Default			|	no			|
|	    STNINIKW 	|	Auto	|	 Append, On clash append '_systemID' (handled before SNINI and changes pushed to STNINI)	|	no			|
|	    STNINI 	|	Auto	|	 increment STNINI.ORDER by 1	| no				|
|	    BENCH 	|	Auto	|	 increment BENCH.BENCH by 1	|	no			|
|	    HISTORY 	|	Auto	|	 increment HISTORY.STATTIME by 1	|	no			|
|	    PERIOD 	|	 Calculated table, leave	| Default |	no			|
|	    INSTHIST 	|	 Manual	| Default |	no			|
|	    SERIES 	|	 Calculated table, leave 	| Default |	no			|
|	    PEAKTIME 	|	 Calculated table, leave 	| Default |	no			|
|	    RATEPER 	|	 Manual	| Default |	no			|
|	    RATEHED 	|	 Manual	| Default |	no			|
|	    RATEPTS 	|	 Manual	| Default |	no			|
|	    RATEEQN 	|	 Manual	| Default |	no			|
|	    TTABHED 	|	 Manual	| Default |	no			|
|	    TTABPTS 	|	 Manual	| Default |	no			|
|	    SSHIFT 	|	 Manual	|	Default	|		no		|
|	    TSHIFT 	|	 Manual	|	Default	|		no		|
|	    GAUGINGS 	|	 Manual	|	Default	|	no			|
|	    GAUGMEAS 	|	 Manual	|	Default	|	no			|
|	    SECTHED 	|	 Manual	|	Default	|	no			|
|	    SECTIONS 	|	 Manual	|	Default	|	no			|
|	    SECTSURV 	|	 Manual	|	Default	|	no			|
|	    NRSTN 	|	 Manual	|	Default	|	no			|
|	    VRWEWA 	|	 Manual	|	Default	|	no			|
|	    VRWMON 	|	 Manual	|	Default	|	no			|
|	    VARIABLE	|	 Auto	|	non-base system variable number will increment by 1 to the next available free number in the base system variable table	|	yes			|
|	    SAMPLES	|	 Auto	|	non-base system SAMPLES.SAMPLENO increment by 1	|	yes			|
|	    RESULTS	|	 Auto	|	non-base system RESULTS.SAMPLENO increment by 1	|	yes			|
|	GWHOLE 	|	 Manual			|	Default				|	no			|
|	GWPIPE 	|	 Manual			|	Default				|	no			|
|	HYDMEAS 	|	 Manual			| Default				|	no			|
|	HYDRLMP 	|	 Manual			| Default				|	no			|
|	COMPANY 	|	 Manual			| Default				|	no			|
|	DRILLER 	|	 Manual			| Default				|	no			|
|	DRILLIC 	|	 Manual			| Default				|	no			|
|	GWHGU	 	|	 Manual			| Default				|	no			|


Default: If key clash, check values, if value clash, report


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

