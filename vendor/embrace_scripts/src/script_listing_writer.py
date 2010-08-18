# BioCatalogue: vendor/embrace_scripts/script_listing_writer.py
#
# Copyright (c) 2010, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details
# *************************************************************************
import MySQLdb
from config_reader import ConfigReader
from setup_logger import SetupLogger

class ScriptListingWriter:
    
    def __init__(self, fn):
        self.configs = ConfigReader(fn).read()
        self.outfile = '../config/script_listing.xml'
        self.logger  = SetupLogger().logger("ScriptListingWriter:")
    
    def get_script_references(self, db):
        self.logger.info("getting script references from db : %s" %s)
        stmt  = "SELECT service_tests.service_id, service_tests.id, test_scripts.exec_name "
        stmt += "FROM service_tests,test_scripts "
        stmt += "WHERE service_tests.test_id =test_scripts.id "
        stmt += "AND service_tests.test_type ='TestScript' AND test_scripts.prog_language <> 'soapui' " 
        stmt += "AND service_tests.activated_at IS NOT NULL ; "
        self.logger.info(stmt)
        results    = db.execute(stmt)
        references = db.fetchall()
        return references 
    
    def get_soapui_references(self, db):
        self.logger.info("getting soapui project references from db : %s" %db)
        stmt  = "SELECT service_tests.service_id, service_tests.id, test_scripts.exec_name "
        stmt += "FROM service_tests,test_scripts "
        stmt += "WHERE service_tests.test_id =test_scripts.id "
        stmt += "AND service_tests.test_type ='TestScript' AND test_scripts.prog_language = 'soapui' " 
        stmt += "AND service_tests.activated_at IS NOT NULL ; "
        self.logger.info(stmt)
        results    = db.execute(stmt)
        references = db.fetchall()
        return references
    
    def write_listing(self, scripts, soapui ):
        self.logger.info("writing script listing file : %s" %self.outfile)
        fh = open(self.outfile, 'w')
        
        fh.write('<test_harness> \n' )
        fh.write('<scripts> \n' )
        for script in scripts:
            fh.write('  <script> \n' )
            fh.write('\t<service_id>%s</service_id> \n'%str(script[0]) )
            fh.write('\t<test_id>%s</test_id> \n'%str(script[1]) )
            fh.write('\t<executable>%s</executable> \n'%str(script[2]) )
            fh.write('  </script> \n\n' )
        
        fh.write('</scripts> \n' )
        
        fh.write('<soapui> \n' )
        for project in soapui:
            fh.write('  <project> \n' )
            fh.write('\t<service_id>%s</service_id> \n'%str(project[0]) )
            fh.write('\t<test_id>%s</test_id> \n'%str(project[1]) )
            fh.write('\t<executable>%s</executable> \n'%str(project[2]) )
            fh.write('  </project> \n\n' )
        
        fh.write('</soapui> \n' )
        fh.write('</test_harness> \n' )
        
        fh.close()
    
    #connect to db
    def connect_to_db(self, host, port, user, passwd, db):
        conn = MySQLdb.connect(host=host, port=port, user=user, passwd=passwd, db=db)
        cursor = conn.cursor()
        self.logger.info("Connected to db : %s" %db )
        return cursor
    

__name__=="__main__"
lw  = ScriptListingWriter('../config/tests_script_runner.config')
db   = lw.connect_to_db(lw.configs['host'], int(lw.configs['port']), 
                        lw.configs['user'], lw.configs['password'], lw.configs['database'])

scripts = lw.get_script_references(db)
soapui  = lw.get_soapui_references(db)
lw.write_listing(scripts, soapui)


