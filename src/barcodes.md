# SAP Barcodes

+ Details about SAP Barcodes
http://www.erpgreat.com/abap/details-information-about-sap-barcodes.htm

+ Questions for bar code printing in SAP
http://www.erpgreat.com/abap/questions-about-bar-code-printing-in-sap.htm

+ Step by step create barcode for smartforms 
https://wiki.scn.sap.com/wiki/display/Snippets/Step-by-step+New+Barcode+Technology+for+Smart+Forms

+ Which barcode printer are you using ? download this file and see.
http://www.servopack.de/Files/HB/ZPLcommands.pdf.



1. SE73 SAPScript Font Maintenance to create or change bar codes.

choose system barcodes. created. 

barcode alignment.
normal -> scan direction is from left to right.
rotated -> scan direction is rotated by 90 degree from top to bottom
inverted -> scan direction is rotated by 180 degree from right to left
bottom-up -> scan direction is rotated by 270 degree from bottom to top

save barcode.

2. import barcode to smartstyles.
tcode SMARTSTYLES
create a style ZSMS_BARCODE

create paragraph format p1 .

create charcter format c1. 

Import the barcode in C1. 

save and activate the styles.

3. create smartforms ZSFS_BARCODE
tcode smartforms.
in form attributes, import style in the output option.

define import parameter into import tab of form interface.


To Create a Bar code prefix:

1) Go to T-code - SPAD -> Full Administration -> Click on Device Type -> Double click the device for which you wish to create the print control -> Click on Print Control tab ->Click on change mode -> Click the plus sign to add a row or prefix say SBP99 (Prefix must start with SBP) -> save you changes , it will ask for request -> create request and save

2) Now when you go to SE73 if you enter SBP00 for you device it will add the newly created Prefix

Create a character format C1.Assign a barcode to the character format.Check the check box for the barcode.

The place where you are using the field value use like this

<C1> &itab-field& </C1>.

You will get the field value in the form of barcode.

Which barcode printer are you using ? Can you download this file and see.

http://www.servopack.de/Files/HB/ZPLcommands.pdf.

It will give an idea about barcode commands.

Check this link:

http://www.sap-img.com/abap/questions-about-bar-code-printing-in-sap.htm

Check this link:

http://help.sap.com/saphelp_nw04/helpdata/en/d9/4a94c851ea11d189570000e829fbbd/content.htm

Hope this link ll be useful..

http://help.sap.com/saphelp_nw04/helpdata/en/66/1b45c136639542a83663072a74a21c/content.htm

Detailed information about SAP Barcodes

A barcode solution consists of the following:

- a barcode printer

- a barcode reader

- a mobile data collection application/program

A barcode label is a special symbology to represent human readable information such as a material number or batch number

in machine readable format.

There are different symbologies for different applications and different industries. Luckily, you need not worry to much about that as the logistics supply chain has mostly standardized on 3 of 9 and 128 barcode symbologies - which all barcode readers support and which SAP support natively in it's printing protocols.

You can print barcodes from SAP by modifying an existing output form.

Behind every output form is a print program that collects all the data and then pass it to the form. The form contains the layout as well as the font, line and paragraph formats. These forms are designed using SAPScript (a very easy but frustratingly simplistic form format language) or SmartForms that is more of a graphical form design tool.

Barcodes are nothing more than a font definition and is part of the style sheet associated with a particular SAPScript form. The most important aspect is to place a parameter in the line of the form that points to the data element that you want to represent as barcode on the form, i.e. material number. Next you need to set the font for that parameter value to one of the supported barcode symbologies.
