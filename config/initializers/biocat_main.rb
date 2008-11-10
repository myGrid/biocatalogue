# Mappings for service types supported, to corresponding model classes.
SERVICE_TYPES = {
  "SOAP Web Service"  => SoapService,
  #"REST Web Service"  => RestService,
  #"Soaplab Server"    => SoaplabServer
}

# Initialise the country codes
CountryCodes

# Require the util library 
require 'util'

# List of all the valid search types available 
# (must be in lowercase and in the plural form and MUST correspond to a resource type in the system)
VALID_SEARCH_TYPES = [ "services", "users" ]
