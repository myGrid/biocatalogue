#!/usr/bin/python
# BioCatalogue : /vendor/embrace_scripts/src/biocat_harness.py
#
# Copyright (c) 2010, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details
#
# This script uses a biocatalogue db to select test scripts to run.
# It is dependent on the scripts which create the run directories 
# from the same database.[make_biocat_test_script_run_dirs.py]

# It create biocat_wrapper and soapuui_runner instances, passing these the 
# the information of the particular test instance to run. It launches these
# as sub processes and polls to find out which ones are done, then deletes those 
# from the list .
# The database setting that it needs to run are passed in a configuration file
# Example:
#    python biocat_harness.py <configuration file>
#################################################################################

import os
import subprocess
import signal
import MySQLdb
import time
import smtplib
import sys
from optparse import OptionParser

from config_reader import ConfigReader
from script_listing_reader import ScriptListingReader
from setup_logger import SetupLogger


MAX_PROCESS_TIME = 60*5           # Scripts should not run run for more than set no of seconds

pool_size       = 10					# process pool size
pool            = {}					# process pool
poll_time       = 30					# length of wait between polls (in seconds)
queue           = []                    # Queue of processes to execute
soapui_jobs     = []
cursor          = None                  # DB connection handle 
completed       = []                    # completed processes 
passed          = []                    # sucessful processes
failed          = []                    # failed processes
total_scripts   = 0
total_soapui    = 0
logger          = SetupLogger().logger("biocat_harness")

# command line options
usage  = "usage: %prog [options] configuration_file"
parser = OptionParser(usage=usage)
parser.add_option("-l", "--log", dest="logfile",
                  help="send output to logfile", metavar="FILE", default="harness-status-%s.log" %(time.strftime("%m%d-%Y-%H%M%S", time.gmtime())))
parser.add_option("-f", "--fromFile", dest="fromFile",
                  help="XML file containing the scripts to be run", metavar="FILE")
parser.add_option("-d", "--database", dest="db", default=False,
                  help="get the scripts to run from a Biocatalogue database")


(options, args) = parser.parse_args()

save_stdout = sys.stdout

if len(args) != 1:
    print "Wrong number of arguments!"
    os.system('python '+ sys.argv[0] + "  --help")
    sys.stdout = save_stdout
    sys.exit(1)


if options.logfile != None:
    log = '../log/' + options.logfile
    print "Sending output to log file ../log/%s"%options.logfile
    logger.info("Sending output to log file ../log/%s"%options.logfile)
    try:
        pass
        log_handle = open(log, 'w')
        sys.stdout = log_handle
    except Exception, e:
        print "Could not create log file, outputing to stdout"
        sys.stdout = save_stdout
        print str(e)

# Booting
print "*******************************************************************************"
print "Booting BioCatalogue Test Harness"
print "Start: %s"%time.ctime()
print "*******************************************************************************"

    
configs = {}
try:
    configs        = ConfigReader(args[0]).read()
except Exception, e:
    print "Could not read the config file"
    print str(e)
    sys.stdout = save_stdout
    sys.exit(1)
    
#wrappers
wrapperpath    = os.path.join(configs['harnessroot'], 'testscript_runner.py') 
soapui_wrapper = os.path.join(configs['harnessroot'], 'soapui_runner.py') 

print options.fromFile
if options.fromFile != None :
    if os.path.exists(options.fromFile):
        queue, soapui_jobs = ScriptListingReader(options.fromFile).parse()
    else:
        print "WARNING: config file, %s  does not exist,"%options.fromFil

if options.db:
    try:
        # connect to DB
        db = MySQLdb.connect(host=configs['host'], port=int(configs['port']), 
                     user=configs['user'], passwd=configs['password'], db=configs['database'])
        cursor = db.cursor()
    except Exception, e:
        print "Could not connect to the database to the get the list of script to run"
        print "Exiting"
        print str(e)
        sys.stdout = save_stdout
        sys.exit()

    #python, perl and ruby scripts
    # Get the tests that need to be run
    try:
        sql_stmt  = "SELECT service_tests.service_id, service_tests.id, test_scripts.exec_name "
        sql_stmt += " FROM test_scripts,service_tests WHERE service_tests.test_id=test_scripts.id "
        sql_stmt += " AND service_tests.test_type='TestScript' "
        sql_stmt += " AND test_scripts.prog_language <>'soapui' ;"
        cursor.execute(sql_stmt)
        queue = cursor.fetchall()

        #soapui tests
        sql_stmt  = "SELECT service_tests.service_id, service_tests.id, test_scripts.exec_name "
        sql_stmt += " FROM test_scripts,service_tests WHERE service_tests.test_id=test_scripts.id "
        sql_stmt += " AND service_tests.test_type='TestScript' "
        sql_stmt += " AND test_scripts.prog_language ='soapui' ;"
        cursor.execute(sql_stmt)
        soapui_jobs = cursor.fetchall()
    
    except Exception, e:
        print "There were problems obtaining the list of script to run from database"
        print "Please check the configuration file"
        print "Exiting..."
        print str(e)
        sys.stdout = save_stdout
        sys.exit(0)

if (len(queue) + len(soapui_jobs)) == 0:
    print "No test were configured. Either run against a BioCatalogue database with tests or provide a configuration file. "
    print "Sample configuration file is found in <RAILS_ROOT/vendor/embrace_script/config/script_listing.xml> \n"
    os.system('python '+ sys.argv[0] + "  --help")
    sys.exit(0)

	
id_list = str([int(id) for (testable_id, id, exec_name) in queue])


print "Queuing", "\nQueuing ".join(["%s/%s/package/%s" % values for values in queue])
#db.commit()

queue       = list(queue)
soapui_jobs = list(soapui_jobs)

def process_timeout(start):
    limit = start + MAX_PROCESS_TIME
    if time.time() > limit:
        print "time out!"
        return True
    return False


# run non soapui test[perl, python, ruby]
total_scripts = len(queue)
print 'INFO : Test Scripts to run         : %d'%len(queue)
print 'INFO : SoapUI project files to run : %d'%len(soapui_jobs)
while len(queue) + len(pool) > 0:
    print "\n------------------------------- Running Test Scripts------------------------------------------------------\n"

    for i in range(0, min([pool_size-len(pool.keys()), len(queue)])):
        (testable_id, id, exec_name) = queue.pop()
        wrappercommand = " ".join((wrapperpath, str(testable_id), str(id), exec_name, args[0]))
        print "INFO: Launching %u/%u/package/%s" % (testable_id, id, exec_name)
        pool[(testable_id, id, exec_name)] = (subprocess.Popen(wrappercommand, stdout = subprocess.PIPE, close_fds = True, shell=True), time.time())

	# wait
	time.sleep(poll_time)
	
	removable = []
    
    for k, (process, start) in pool.iteritems():  # k = (testable_id, id, exec_name)
        ret = process.poll()
        if ret != None:
            if not k in removable:
                print "INFO: Completed %u/%u/package/%s" % k
                removable.append(k)
                completed.append(k)
                if ret == 0:
                    passed.append(k) 
                    print "INFO: OK"
                else:
                    failed.append(k)
                    print "INFO: FAILED"
        else:             
            if process_timeout(start):
                if not k in removable:
                    print "ERROR: Precess timed out !! Terminating %u/%u/package/%s" % k
                    #kill chidl process
                    os.system('kill -9 %d' %process.pid)
                    removable.append(k)
                    completed.append(k)
                
    for key in removable:
        if key in pool.keys():
		      del pool[key]


total_soapui = len(soapui_jobs)    
pending = len(queue) + len(soapui_jobs)
print "\n\n********************************Summary Update**************************************\n"
print "Jobs pending    : %d"%pending
print "Executing       : %d"%len(pool.keys())
print "Jobs completed  : %d"%len(completed)
print "Wrapper OK      : %d"%len(passed)
print "Wrapper failed  : %d"%len(failed)
print "**************************************************************************************\n"

# soapui project files execution
while len(soapui_jobs) + len(pool) > 0:
    print '---------------------------------------Running SoapUI Projects---------------------------------------------------- '

    for i in range(0, min([pool_size-len(pool), len(soapui_jobs)])):
        (testable_id, id, exec_name) = soapui_jobs.pop()
        wrappercommand = " ".join((soapui_wrapper, str(testable_id), str(id), exec_name, args[0]))
        print "INFO : Launching %u/%u/package/%s" % (testable_id, id, exec_name)
        pool[(testable_id, id, exec_name)] = (subprocess.Popen(wrappercommand, stdout = subprocess.PIPE, close_fds = True, shell=True), time.time())

    # wait
    time.sleep(poll_time)
    
    removable = []
    
    # gather completed wrapper processes
    for k , (process, start) in pool.iteritems():   #k = (testable_id, id, exec_name)
        # poll process state
        ret = process.poll()
        if ret != None:         # process complete
            if not k in removable:
                print "INFO: Completed %u/%u/package/%s" % k
                completed.append(k)
                removable.append(k)
                if ret == 0:
                    passed.append(k)
                    print "INFO: OK"
                else:
                    failed.append(k)
                    print  "INFO: FAILED"
        else:
            if process_timeout(start):
                #kill the subprocess. Only works on unix
                if not k in removable:
                    print "ERROR: Precess timed out !! Terminating %u/%u/package/%s" % k
                    os.system('kill -9 %'%process.pid)
                    removable.append(k)
                
    for key in removable:
        if key in pool.keys():
            del pool[key]
            print "Deleted completed process  %u/%u/package/%s" %key
    
print "\n\n********************************Summary Update*****************************\n"
pending = len(queue) + len(soapui_jobs)
print "Jobs pending    : %d" % pending
print "Executing       : %d" % len(pool.keys())
print "Jobs completed  : %d" % len(completed)
print "Wrapper OK      : %d" % len(passed)
print "Wrapper Failed  : %d" % len(failed)
print "*****************************************************************************\n"

      

print "*******************************************************************************"
print "BioCatalogue Test Harness Completed Successfully"
print "End : %s"%time.ctime()
print "*******************************************************************************"

#restore stdout
sys.stdout = save_stdout