#!/usr/bin/python

#BioCatalogue : /vendor/embrace_scripts/src/testscript_runner.py

# This script runs test scripts against web services. 
# Tests are scripts that are executable on the command line and take no arguments 
# The command-line script is launched as a subprocess which is killed if it exceeds
# a hard timeout. When the subprocess completes, it exit code is posted to a url (biocatalogue).
# The configurations for running this script are put in file whose path is passed
# as a command line argument to this script. Other arguments passed are the ids if the test script
# and the service to which it belongs.
# Example:
# python testscript_runner.py <service id> <test id> <test script name> <configuration file>

import os
import subprocess
import time
import sys
import random
import signal
import datetime
from optparse import OptionParser

from config_reader import ConfigReader
from test_result import TestResult

class TestScriptRunner:
    def __init__(self, configs):
        self.configs = configs
        self.timeout    = 30 * 60        # length of timeout (in seconds)
        self.kill_delay = 2  
        self.returncode = 1  
        self.result     = 1              # 1 = there were problems, 0 = everything was fine
        self.summary    = ''
        self.configure()
    
    def configure(self):
        self.runner_location = self.configs.get('script_runner_dir')
        self.execution_root   = self.configs.get('execution_root')
    
    def command(self, service_id, test_id, script_name, conf_file):
        self.service_id   = service_id
        self.test_id      = test_id
        self.script_name  = script_name
        self.test_dir     = os.path.join(self.execution_root, str(service_id), str(test_id))
        self.work_dir     = os.path.join(self.test_dir, 'package')
        self.log          = os.path.join(self.test_dir, os.path.join("logs", ("%s.tmp.log" % datetime.datetime.now()))) 
        
        self.cmd = os.path.join(self.work_dir, self.script_name)
        print self.cmd +' %s'%conf_file
        return self.cmd +' %s'%conf_file
    
    def post_result(self, url, user, psswd):
        print "Posting result to  %s"%url
        conf = {'result' : int(self.result),
                'message' : self.summary,
                'action'  : self.script_name,
                'test_id' : int(self.test_id) }
        tr = TestResult(conf)
        return tr.post(url, user, psswd)
    
    def signal_handler(self, signum, child):
        os.kill(child.pid, signal.SIGKILL)
    
if __name__ =='__main__':
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
        configs = ConfigReader(args[3]).read()
    except Exception, e:
        print "Could not read the config file"
        print str(e)
        sys.exit(1)
        
#    if len(sys.argv) != 4:
#        print 'Usage: testscript_runner.py <service id> <test id > <test script filename >'
#        exit(1)
#    configs = ConfigReader('../config/tests_script_runner.config').read()
    runner  = TestScriptRunner(configs)
    command = runner.command(args[0], args[1], args[2], args[3])
    child   = None
    
    try:
        print "running job : %s "%runner.script_name
        logfile = open(runner.log, 'w')
        prev_handler = signal.signal(signal.SIGALRM, runner.signal_handler)
        signal.alarm(runner.timeout)
        print runner.cmd
        child = subprocess.Popen("%s" % runner.cmd, stdout= logfile, stderr= logfile, close_fds = True, shell= True, cwd=runner.work_dir)
        
        runner.returncode = child.wait()
        runner.result     = runner.returncode
        signal.alarm(0)
    
        logfile  = open(runner.log)
        runner.summary = "".join(logfile.readlines())
        logfile.close()
        print runner.returncode
    except Exception, e:
        #sys.stdout = stdout_bak
        runner.summary  += "Test Wrapper failure"
        #runner.summary  += str(e)
        # make a note in the logfile if the process was forcefully killed
        time.sleep(runner.kill_delay)
        if child != None:
            if child.poll() < 0:
                logfile = open(runner.log, 'a+')
                logfile.write("*** Process was killed, since it did not terminate within %u seconds. ***\n" % runner.timeout)
                logfile.close()

    #signal.signal(signal.SIGALRM, runner.prev_handler)
    runner.post_result(configs['result_url'], configs['api_user'], configs['api_pass'])
    print "Wrapper completed with child status", runner.returncode