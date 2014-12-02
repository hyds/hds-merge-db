hds-merge-db
============

This HYSCRIPT aims to merge two or more large Hydstra(TM) systems into one system.

## Synopsis

Mergify-hy assumes that when merging two or more Hydstra systems, you will want to keep one of the systems intact. This is called the "base system". 

If there are clashes in the keys and values of records between the base system and another source system, the base system will not be modified.

Therefore the other source systems will need to be modified in some way to retain the records, and not overwrite the base system. The basic process involved here is:

 * If the source systems are dbf files, convert dbf into csv
 * Clashes in Variable tables will increment the non-base system variable number to the next available free number in the base system variable table
 * Clashes in WQ tables will increment the SAMPLENO by 1 - NOT IMPLEMENTED
 * Clashes in GW tables - NOT IMPLEMENTED

The script also assumes that you are using potentially large tables, like WQ tables, with millions of rows, and so it caches data in a provisional, dated SQLite database.

In order to store data in SQL tables Hydstra tables have been defined in other modules using OO Perl. hence it has dependencies, all of which can be downloaded from GitHub

## Dependencies

* Hydstra
* ToSQLite
* Mergify
* fs
* import
* export

## Parameter screen

The systems and tables you want to merge are configured in the INI file, so you only have one button, and a report destination.

![Parameter screen](/images/psc.PNG)

## INI configuration

![INI file](/images/ini.png)

## Version

Version 0.01
  
## Bugs

Please report any bugs in the issues wiki.

