hds-merge-db
============

This HYSCRIPT aims to merge two or more large Hydstra(TM) systems into one system.

## Synopsis

Mergify-hy assumes that when merging two or more Hydstra systems, you will want to keep one of the systems intact. This is called the "base system". 

If there are clashes in the keys and values of records between the base system and another system, the base system will not be modified.

Therefore the other source systems will need to be modified in some way to retain the record, but not overwrite the base system.

The script also assumes that you are using potentially large tables, like WQ tables, with millions of rows, and so it caches data in a provisional, dated SQLite database.

## Parameter screen

The systems and tables you want to merge are configured in the INI file, so you only have one button, and a report destination.

![Parameter screen](/images/psc.PNG)

## INI configuration

![INI file](/images/ini.png)

## Process

The basic process involved here is:

1. DBF Conversion to CSV (if selected, otherwise assuem CSVs are there)
2. Import base system to temp SQLite.db
3. Import non-base systems to temp SQLite.db and handle clashes
4. Export a merged system from the temp SQLite.db to HYCLIPIN files
5. Manually import the HYCLIPIN files to your final system

## Clashes
 
### Clashes in SITE tables

Usually there are complex business rules for naming a site. These differ between businesses and between projects. Due to this variabiliyt, no automation has been implemented and checking for clashes will need to be done manually. So the SITE table itself is assumed to have no clashes.

* If there is a site number in a non-base system (which is not a clash) it will be imported to the base system

### Clashes in Variable tables 

* The base system will be preserved and non-base system variable number will increment by 1 to the next available free number in the base system variable table

### Clashes in WQ tables

* The base system will be preserved and non-base system will increment the SAMPLENO by 1

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

## Version

Version 0.02
  
## Bugs

Please report any bugs in the issues wiki.

