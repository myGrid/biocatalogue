# BioCatalogue: vendor/embrace_scripts/setup_logger.py
#
# Copyright (c) 2010, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details
# *************************************************************************

import logging
import logging.handlers

LOG_FILENAME = '../log/application.log'

class SetupLogger:
    
    def __init__(self):
        pass
        
    def logger(self, name=""):
        if name =="":
            name = "TestScriptHarness"
        # create logger
        logger = logging.getLogger(name)
        logger.setLevel(logging.DEBUG)
        
        # create console handler and set level to debug
        ch = logging.StreamHandler()
        ch.setLevel(logging.DEBUG)
        
        # create formatter
        formatter = logging.Formatter("%(asctime)s - %(name)s - %(levelname)s - %(message)s")
        # add formatter to ch
        ch.setFormatter(formatter)
        # add ch to logger
        logger.addHandler(ch)
        
        # Add the log message handler to the logger
        fh = logging.handlers.RotatingFileHandler(LOG_FILENAME, maxBytes=1024*2000, backupCount=10)
        fh.setFormatter(formatter)
        logger.addHandler(fh)
        
        return logger

if __name__=="__main__":
    logger = SetupLogger().logger()
    # "application" code
    logger.debug("debug message")
    logger.info("info message")
    logger.warn("warn message")
    logger.error("error message")
    logger.critical("critical message")