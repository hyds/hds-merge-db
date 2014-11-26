# Mergify-hy

This HYSCRIPT aims to merge two or more large Hydstra(TM) systems into one system.

## Synopsis

Mergify-hy assumes that when merging two or more Hydstra systems, you will want to keep one of the systems intact. This is called the "base system". 

If there are clashes in the keys and values of records between the base system and another source system, the base system will not be modified.

Therefore the other source systems will need to be modified in some way to retain the records, and not overwrite the base system. The basic process involved here is:

 * If the source systems are dbf files, convert dbf into csv
 * Clashes in Variable tables will increment the non-base system variable number to the next available number
 * Clashes in WQ tables will increment the SAMPLENO by 1
 * Clashes in GW tables will not be resolvable simply, and will need to 

The script also assumes that you are using potentially large tables, like WQ tables, and so caches data in a provisional, dated SQLite database

## Parameter screen

![Parameter screen](/images/psc.png)

## INI configuration

![INI file](/images/ini.png)

## Version

Version 0.01
  
## Author

Sholto Maud, C<< <sholto.maud at gmail.com> >>

## Bugs

Please report any bugs in the issues wiki.


# LICENSE AND COPYRIGHT

Copyright 2014 Sholto Maud.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


