# BioCatalogue: app/config/initializers/biocat_main.rb
#
# Copyright (c) 2008, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

# Mappings for service types supported, to corresponding model class names.
SERVICE_TYPES = {
  "SOAP Web Service"  => "SoapService",
  #"REST Web Service"  => "RestService",
  #"Soaplab Server"    => "SoaplabServer"
}

# Initialise the country codes
CountryCodes

# Require the util library 
require 'util'

# List of all the valid search types available, in the order they should be shown.
# (must be in lowercase and in the plural form and MUST correspond to a resource type in the system)
VALID_SEARCH_TYPES = [ "services", "users", "service_providers" ]

# Set up loggers to STDOUT if in script/console (so now things like SQL queries etc are shown in the console).
if "irb" == $0
  ActiveRecord::Base.logger = Logger.new(STDOUT)
  ActionController::Base.logger = Logger.new(STDOUT)
end

# Set global pagination per_page parameter in all models.
class ActiveRecord::Base
  cattr_reader :per_page
  @@per_page = 10
end

# ==========
# Configure the Annotations plugin...
# ----------

# Remember that all attribute names specified MUST be in lowercase

Annotations::Config.attribute_names_for_values_to_be_downcased.concat([ "tag" ])

Annotations::Config.strip_text_rules.update({ "tag" => [ '"' ] })

# ==========
