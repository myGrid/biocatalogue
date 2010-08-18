# BioCatalogue: vendor/embrace_scripts/config_reader.py
#
# Copyright (c) 2010, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details
# *************************************************************************

from setup_logger import SetupLogger

class ConfigReader:
    def __init__(self, config_file):
        self.config = config_file
        self.logger = SetupLogger().logger("ConfigReader")
        
    def read(self):
        self.logger.debug("Reading the config file")
        params = {}
        lines = open(self.config,'r').readlines()
        lines = [line.strip() for line in lines]
        for line in lines:
            #skip empty lines and comment lines
            if not line.startswith('#') and line.strip():
                k,v = line.split('=') 
                params[k.strip()] = v.strip()
        #print "Done"
        return params
    

if __name__ == "__main__":
    cr = ConfigReader('../config/tests_script_runner.config')
    print cr.read()