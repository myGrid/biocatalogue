#!/usr/bin/python
################################################################
#
# This scripts wraps a test scripts and executes it
# as a sub process. If the script does not complete within
# half an hour, it is kill and a corresponding message inserted
# in the log
#
# The script then posts the result (exit code) of the script to 
# to a url specified in a config file under ../config/


import datetime
import os, subprocess
import time
import MySQLdb
from MySQLdb import escape_string
import sys
import md5
import random
import signal
from optparse import OptionParser

from config_reader import ConfigReader

timeout    = 30 * 60		# length of timeout (in seconds)
kill_delay = 2			    # number of seconds that have to pass before proceeding after a process is killed

# command line options
usage  = "usage: %prog [options] service_id test_id path_to_executable config_file"
parser = OptionParser(usage=usage)
parser.add_option("-l", "--log", dest="logfile",
                  help="send output to a log file", metavar="FILE")
(options, args) = parser.parse_args()

if len(args) != 4:
    print "Wrong number of arguments!"
    os.system('python '+ sys.argv[0] + "  --help")
    sys.exit(1)

configs = {}
try:
    configs        = ConfigReader(args[3]).read()
except Exception, e:
    print "Could not read the config file"
    print str(e)
    sys.exit(1)
    
#configs     = ConfigReader('../config/tests_script_runner.config').read()
harnessroot = configs['harnessroot']
result_url  = configs['result_url']


def signal_handler(signum, frame):
	os.kill(child.pid, signal.SIGKILL)

#if len(sys.argv) != 4:
#    print "Usage: testharness [service_id] [testid] [path to executable]"
#    sys.exit()

try:
	testid= int(args[1])
except:
	print "Error: second parameter must be an integer"
	sys.exit(1)

try:
	serviceid= int(args[0])
except:
	print "Error: first parameter must be an integer"

response= ''
err_string = 'Test passed'
returncode= 0

startdate= time.strftime("%Y-%m-%d %H:%M:%S")
print startdate

db = MySQLdb.connect(host=configs['host'],user=configs['user'], 
					   passwd=configs['password'], db=configs['database'])

cursor = db.cursor()

#test run dir
testdir  = os.path.join(configs['execution_root'], os.path.join(sys.argv[1], sys.argv[2]))
cwd = os.path.join(testdir, "package")
logfilename = os.path.join(testdir, os.path.join("logs", ("%s.tmp.log" % datetime.datetime.now())))

try:
	logfile = open(logfilename, 'w')
	prev_handler = signal.signal(signal.SIGALRM, signal_handler)
	signal.alarm(timeout)
	print os.path.join(cwd,sys.argv[3])
	print os.path.join(cwd, args[2])
	child = subprocess.Popen("./%s" % args[2], stdout= logfile, stderr= logfile, close_fds = True, shell= True, cwd=cwd)
		
	returncode = child.wait()
	signal.alarm(0)
	
	logfile = open(logfilename)
	response = "".join(logfile.readlines())
	logfile.close()
	
except:
	sys.stdout = stdout_bak
	err_string = "Test Wrapper failure"
	returncode= 1
	print sys.exc_info()
	# make a note in the logfile if the process was forcefully killed
	time.sleep(kill_delay)
	if child.poll() < 0:
		logfile = open(logfilename, 'a+')
		logfile.write("*** Process was killed, since it did not terminate within %u seconds. ***\n" % timeout)
		logfile.close()

signal.signal(signal.SIGALRM, prev_handler)

print "Harness completed; script return", returncode, "with child status", child.poll()

enddate= time.strftime("%Y-%m-%d %H:%M:%S")

comments = """Test began: %s ; Test ended: %s ;  Result : %s """ % (startdate, enddate, returncode)

def service_test_id(script_id):
	stmt = "SELECT id from service_tests WHERE test_type='TestScript' and test_id=%d ;"%script_id
	results    = cursor.execute(stmt)
	reference = cursor.fetchone()
	return reference[0]
   

#--------------------------------------------------------------------------------------------------------------

def save_result(test_id, result, action, message, start, end, dbcursor):
	st_id = service_test_id(test_id)
	try:
		statement  = "INSERT INTO test_results (`service_test_id`, `test_id`, `test_type`, `result`, `action`, `message`, `created_at`, `updated_at`) "
		statement += "VALUES (%d, %s, '%s', %d, '%s', '%s', '%s', '%s') ;" %(int(st_id), int(test_id), "TestScript", int(result), action, escape_string(message), start, end) 
		dbcursor.execute(statement)
		db.commit()
	except Exception, e:
		logfile = open(logfilename, 'a+')
		logfile.write(str(e))
		logfile.close()
#----------------------------------------------------------------------------------
def translate_result(exitcode):
	returnresult = PASSED
	err_string   = ""
	if exitcode == 1:
		returnresult = FAILED
		err_string = "Test failure"
	elif exitcode > 1:
		returnresult = WARNING
		err_string = "Test warning"
	return (returnresult, err_string)
#---------------------------------------------------------------------------------



#---------------------------------------------------------------------------------
def log_contents(log):
	msg = ''
	lines = open(log, 'r').readlines()
	for line in lines:
		msg += line
	return msg 


   
# User curl to post the test results back to the application
def post_result_with_curl(url, test_id, return_code, action, message=''):
	
    test_type ="TestScript"
    user      = configs['api_user']
    password  = configs['api_pass']
    #message   = log_contents(logfilename)
    
    data = '<?xml version="1.0"?>' 
    data +='<test_result> '
    data +='<result>%d</result>'%(return_code)
    data +='<action>%s</action>'%(action)
    data +='<message>%s</message>'%(message)
    data +='<service_test_id>%d</service_test_id>'%(test_id)
    data +='</test_result>'   
    curl = "curl -X POST -u %s:%s -d '%s' -H 'Content-Type:application/xml' %s" %(user, password,data, url)
    print curl
    
    try:
        retcode = subprocess.call(curl, shell=True)
        if retcode < 0:
            print >>sys.stderr, "Child was terminated by signal", -retcode
            return False
        elif retcode > 0:
            print >>sys.stderr, "There were problems with posting the result ", retcode
            #print >>sys.stderr, "Child returned", retcode
            return False
        else:
            print >> sys.stdout, "Result was posted successfully "
            return True
    except OSError, e:
            print >>sys.stderr, "Exception while posting result:", e
            return False
    return True

###---------------------------------------------------------------------------------------
try:
	posted = post_result_with_curl(result_url, testid, returncode, sys.argv[3], comments)
	if posted:
		#save_result(testid, returncode, sys.argv[3], comments, startdate, enddate, cursor)
		print "result posted successfully"
	else:
		comments += ": Result NOT Posted"
		print comments
		#save_result(testid, returncode, sys.argv[3], comments, startdate, enddate, cursor)
except Exception, e:
	print "There was a problem posting result to %s "%result_url
	print str(e)
##----------------------------------------------------------------------------------------



## print comments before stdio of the process is added, since otherwise the process might block
## because of a full stdout-buffer (for example with hk-test.pl...)
print comments

if response:
  comments += "\n------ stderr and stdout follow ------\n%s" % response
sys.stdout.flush()

print "Wrapper is going to exit successfully"
