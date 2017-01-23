installPrinterFromWindowsPrintServer.sh
===========

This script takes arguments 4-11 to install a printer from a designated print
server. If anything is passed to $6 (Driver Policy Trigger), it will be used
as a custom trigger for a Jamf policy designated to install the driver. Using
normal Jamf scoping mechanisms, you can avoid this policy being re-run when it
is not necessary.

+-----+-----------------------+-----------------------------------------------------------------+
| Arg | Parameter Label       | Example                                                         |
+-----+-----------------------+-----------------------------------------------------------------+
|  $4 | Printer Name          | ITS-Printer1                                                    |
|  $5 | Printer Location      | 5127 OWP                                                        |
|  $6 | Driver Policy Trigger | printDrivers-Bizhub_C224_C284_C364_C454_C554                    |
|  $7 | Driver PPD Path       | /Library/Printers/PPDs/Contents/Resources/KONICAMINOLTAC224e.gz |
|  $8 | Option 1              | PaperSources=PC204                                              |
|  $9 | Option 2              | Finisher=FS519                                                  |
| $10 | Option 3              | SelectColor=Grayscale                                           |
| $11 | Option 4              | ColorModel=Gray                                                 |
+-----+-----------------------+-----------------------------------------------------------------+
