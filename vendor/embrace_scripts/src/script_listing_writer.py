
import MySQLdb
from config_reader import ConfigReader

class ScriptListingWriter:
    
    def __init__(self, fn):
        self.configs = ConfigReader(fn).read()
        self.outfile = '../config/script_listing.xml'
    
    def get_script_references(self, db):
        
        stmt  = "SELECT service_tests.service_id, service_tests.id, test_scripts.exec_name "
        stmt += "FROM service_tests,test_scripts "
        stmt += "WHERE service_tests.test_id =test_scripts.id "
        stmt += "AND service_tests.test_type ='TestScript' AND test_scripts.prog_language <> 'soapui' " 
        stmt += "AND test_scripts.activated_at IS NOT NULL ; "
        
        results    = db.execute(stmt)
        references = db.fetchall()
        return references 
    
    def get_soapui_references(self, db):
        
        stmt  = "SELECT service_tests.service_id, service_tests.id, test_scripts.exec_name "
        stmt += "FROM service_tests,test_scripts "
        stmt += "WHERE service_tests.test_id =test_scripts.id "
        stmt += "AND service_tests.test_type ='TestScript' AND test_scripts.prog_language = 'soapui' " 
        stmt += "AND test_scripts.activated_at IS NOT NULL ; "
        
        results    = db.execute(stmt)
        references = db.fetchall()
        return references
    
    def write_listing(self, scripts, soapui ):
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
        print "Connected to db"
        return cursor
    

__name__=="__main__"
lw  = ScriptListingWriter('../config/tests_script_runner.config')
db   = lw.connect_to_db(lw.configs['host'], int(lw.configs['port']), 
                        lw.configs['user'], lw.configs['password'], lw.configs['database'])

scripts = lw.get_script_references(db)
soapui  = lw.get_soapui_references(db)
lw.write_listing(scripts, soapui)


