#!/usr/bin/python
#
# This script builds the run directories that will be used by
# harness.py and wrapper.py to run the test scripts.
# The scripts uses the biocatalogue registry database to build the directories 
# using the pattern 
# <base_dir>/<service id>/<test_id>/package/>
#

# task to manage embrace tests scripts
import os
import MySQLdb
from config_reader import ConfigReader


class DirectoryMaker:
    def __init__(self, fn):
        self.configs = ConfigReader(fn).read()
        
    def get_script_references(self, db):
        
        #stmt  = "SELECT service_tests.service_id, service_tests.test_id, test_scripts.filename, content_blobs.data "
        stmt  = "SELECT service_tests.service_id, service_tests.id, test_scripts.filename, content_blobs.data "
        stmt += "FROM service_tests,test_scripts,content_blobs  "
        stmt += "WHERE service_tests.test_id = test_scripts.id AND service_tests.test_type ='TestScript' "
        stmt += "AND test_scripts.content_blob_id = content_blobs.id AND service_tests.activated_at IS NOT NULL; " 
        
        results    = db.execute(stmt)
        references = db.fetchall()
        return references 
    
    #make dirs of pattern <base_dir>/<service id>/<test_id>/package/ 
    def setup_run_dirs(self, base_dir, results =[]):
        if not os.path.exists(base_dir): return "ERROR! test base dir %s does not exist"%base_dir
        for result in results:
            service_id = result[0]
            test_id    = result[1]
            run_dir    = os.path.join(base_dir, str(service_id), str(test_id), 'package')
            
            if not os.path.exists(run_dir):
                self.create_run_dir(run_dir, result[2], result[3])
                print "Created test script run directory %s"%run_dir
            else:
                print "Test script run directory %s already exists "%run_dir
            
    # create the directory to run the jobs
    def create_run_dir(self, dir, fname, data):
        cwd = os.getcwd()
        base, package    = os.path.split(dir)
        base, test_id    = os.path.split(base)
        base, service_id = os.path.split(base)
        try:
            if not os.path.exists(os.path.join(base, service_id)): 
                os.mkdir(os.path.join(base, service_id))
            if not os.path.exists(os.path.join(base, service_id, test_id)):
                os.mkdir(os.path.join(base, service_id, test_id))
            os.mkdir(dir)
            os.mkdir(os.path.join(os.path.split(dir)[0], "logs"))
        except Exception, e:
            e.stacktrace()
        if not os.path.exists(os.path.join(dir, fname)):
            if data != None:
                try:
                    fh = open(os.path.join(dir, fname), 'wb')   
                    fh.write(data)
                    fh.close()
                    
                    if self.is_zip(fname):
                        os.chdir(dir)
                        os.system("unzip %s"%fname )
                        os.chdir(cwd)
                    cmd = "chmod -R u=rxw  %s"%dir
                    print cmd
                    os.system(cmd)
                except Exception, e:
                    print str(e)
    
    def is_zip(self, fname):
        ext = fname.split('.')[-1]
        if ext=="zip" or ext=="ZIP":
            return True
        return False
    
    #connect to db
    def connect_to_db(self, host, port, user, passwd, db):
        conn = MySQLdb.connect(host=host, port=port, user=user, passwd=passwd, db=db)
        cursor = conn.cursor()
        print "Connected to db"
        return cursor
    

__name__=="__main__"
dm  = DirectoryMaker('../config/tests_script_runner.config')
db   = dm.connect_to_db(dm.configs['host'], int(dm.configs['port']), 
                        dm.configs['user'], dm.configs['password'], dm.configs['database'])

refs = dm.get_script_references(db)
#dm.setup_run_dirs("/Users/ericnzuobontane/tmp", refs)
dm.setup_run_dirs(dm.configs['execution_root'], refs)
