# Version

Version 0.02

# Synopsis

This HYSCRIPT aims to merge two or more large Hydstra(TM) FoxPro systems into one system. Typically you should not perform the merge task on a production system, but rather on a copy of that system

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

You may have already converted the DBF files to CSV previously. If this is the case then uncheck the DBF box.

![Parameter screen](/images/psc.PNG)

## INI configuration

In the INI config file you can select a few of the DBF files for merging from your copy of DBFPATH. 

You MUST have a 'base' system which is the one that will be the starting point to which others are compared. All other subsection names are arbitrary except for the 'base' subsection name which has a fixed meaning so be careful. The base system will not be changed, whilst others may be if they clash with the base system

![INI file](/images/ini.png)

### Default Actions
If you specify a table = 1, you will get the default action which is to simply report on any clashes. This means that the base system is not altered.

``` ini

site = 1 
results = 1
samples = 1

```

### Clash Actions
You can specify a set of finite actions that you want the script to perform when it finds a clash. Action options are increment, decrement, append, prepend.
The actions are essentially your business rules for merging. 

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

For the example above, we will have changed the RESULTS table with no respect for the SAMPLES table. 
So we have potentially just created orphan records.
To take care of orphans can simply say that the RESULTS table was subordinate to the SAMPLES table.
This way, when a clash occurs, any changes that are made to SAMPLES.SAMPNUM will cascade down to the RESULTS table. 
We could specify such like so:

``` ini

samples = {keys:[{fieldname:"sampnum",action:"increment",value:1}],subordinates:["results"]}

```

If this was a groundwater table like GWHOLE you might want to increment the HOLE field by one and cascade this down to all subordinate tables, and you would do such thus:

``` ini

gwhole = { keys:[{fieldname:"hole",action:"increment",value:1}],subordinates:["gwpipe","hydmeas","hydrlmp","casing","aquifer","drilling"]}

```

### Variables

Due to the baroque nature of the field naming conventions in the Hydstra VARIABLE tables we need to be careful to handle the different field names correctly, and cascade them correctly to the subordinate tables. Don't change this section if you don't know what you are doing. If you do know what you are doing, just make sure that all the of actions and values are the same otherwise you will corrupt the association of VARIABLE numbers and actual data. 

You need to make sure that: 

1. you have the correct field name, because this changes between tables 
2. any table that has a variable number in the key is listed in the subortinates
3. you specify the correct number format for the key with the "combined_var":"prefix/suffix" tag because some fields 

Point #3 above is required because some key fields in the target tables are a combination of key fields in the source tables ... it's complex. So becaue you might have multiple keys that you wish to change you need to tell the script how to cascade the parent field to the child tables.

``` ini

variable 	= 	{ "keys": [{ "field":"varnum", "action":"increment", "value":1, "combined_var":"prefix","subordinates":[{"table":"wqvar","field":"variable"},{"table":"varsub","field":"variable"},{"table":"varcon"},{"table":"results"},{"table":"hydmeas","field":"variable"},{"table":"gwtrace","field":"variable"}] }] }

```

## Script process

The basic process that the script steps through is:

1. DBF Conversion to CSV (if selected, otherwise assuem CSVs are there)
2. Import base system to temp SQLite.db
3. Import non-base systems to temp SQLite.db and handle clashes
4. Export a merged system from the temp SQLite.db to HYCLIPIN files
5. Manually import the HYCLIPIN files to your final system

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

