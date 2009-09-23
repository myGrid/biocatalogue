# BioCatalogue: vendor/wsdl-parsing-service/README.txt
#
# Copyright (c) 2009, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

WSDLUtil Library
----------------

Introduction
------------
The WSDLUtils Library was developed by Dan Mowbray for the EMBRACE web services registry. This registry is precursor to the
the BioCatalogue.

Functions
---------
The WDSDLUtils library has two main functions:
 - parse a WDSL file into a format that is consumable by the BioCatalogue registry
 - track changes in a WSDL document
 
 Installation
 ------------
 The utilities in this library are written in PHP and hence would run a web server with PHP enabled.
 
 The library is packaged as a tarball (WSDLUtils.tar.gz). To install it, de-compress the archive
 and move it to the document root of the your web server. The library will reside in a folder
 called "WSDLUtil"
 To test your installation, call the wsdl parse utility as follow:
 
 http://<my server root>/WSDLUtils/WSDLUtils.php?method=parse&wsdl_uri="my test wsdl uri"
 
 
 Using the Library in BioCatalogue for Parsing
 ---------------------------------------------
 
Set the WSDLUtils parser location in  "config/initializers/biocat_local.rb"

Example
WSDLUTILS_BASE_URI = 'http://test.biocatalogue.org/WSDLUtils/WSDLUtils.php'

Use the library in the application in the following way:

BioCatalogue::WSDLUtils::WSDLParser.parse("wsdl_url")

where "wsdl_url" is the wsdl you want to parse. You could test this in the rails console as well.


Resources
---------
Complete documentation by the author is available at
http://www.biocatalogue.org/wiki/doku.php?id=development:wsdl_parsing

TODO
----
Extend this README for the WSDL tracking function.