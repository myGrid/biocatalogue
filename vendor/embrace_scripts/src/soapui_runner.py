#!/usr/bin/python

#BioCatalogue : /vendor/embrace_scripts/src/soapui_runner.py
#
# Copyright (c) 2010, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details
# *************************************************************************

# This script uses the soapUI command line tool to
# run tests against web services. The tests are configured
# in a soapUI project file xml file

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
from setup_logger import SetupLogger


class SoapUIRunner:
    def __init__(self, configs):
        self.timeout    = 30 * 60        # length of timeout (in seconds)
        self.kill_delay = 2  
        self.returncode = 1  
        self.result     = 1              # 1 = there were problems, 0 = everything was fine
        self.summary    = ''
        self.configs    = configs
        self.configure()
        self.logger     = SetupLogger().logger("SoapUIRunner")
    
    def configure(self):
        self.runner_location = self.configs.get('soapui_runner_dir')
        self.execution_root   = self.configs.get('execution_root')
    
    def command(self, service_id, test_id, project_file):
        self.service_id   = service_id
        self.test_id      = test_id
        self.project_file = project_file
        self.test_dir     = os.path.join(self.execution_root, str(service_id), str(test_id))
        self.work_dir     = os.path.join(self.test_dir, 'package')
        self.log          = os.path.join(self.test_dir, os.path.join("logs", ("%s.tmp.log" % datetime.datetime.now()))) 
        
        options = ' -a -r -f %s '%self.work_dir
        cmd  = os.path.join(self.runner_location, 'testrunner.sh' )
        cmd +=' %s ' %options
        cmd +=' %s ' %os.path.join(self.work_dir, self.project_file)
        self.cmd = cmd
        self.logger.debug( cmd)
        return cmd
    
    def parse_log(self, log=''):
        if log=='' : log = self.log
        try:
            lines = open(log, 'r').readlines()
            lines = [line for line in lines if (line.startswith('SoapUI') 
                                                or line.startswith('Time')
                                                or line.startswith('Total') )]
            result_line = [line for line in lines if line.startswith('Total TestCases:')]
            for line in lines:
                self.summary += line
            
            if len(result_line) == 1:
                parts  = result_line[0].split()
                total  = parts[2]
                failed = parts[3][1:]
                if int(failed) == 0 :
                    self.result  = 0
                else:
                    self.result  = 1
                
            print "Overall result %s "% self.result
            print "Summary Report"
            print self.summary
            
        except Exception, e:
            print "There were problems parsing the log"
            print str(e)
    
    def signal_handler(self, signum, child):
        os.kill(child.pid, signal.SIGKILL)
    
    def post_result(self, url, user, psswd):
        print "Posting result to  %s"%url
        conf = {'result' : int(self.result),
                'message' : self.summary,
                'action'  : self.project_file,
                'test_id' : int(self.test_id) }
        tr = TestResult(conf)
        return tr.post(url, user, psswd)

    
if __name__ =='__main__':
#    if len(sys.argv) != 4:
#        print 'Usage: soapui_runner.py <service id> <test id > <soapui project file>'
#        exit(1)
#    configs = ConfigReader('../config/tests_script_runner.config').read()
    
    usage  = "usage: %prog [options] <service_id> <test_id> <soapui_project_file> <config_file>"
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
    
    
    runner  = SoapUIRunner(configs)
    command = runner.command(sys.argv[1], sys.argv[2], sys.argv[3])
    child   = None
    
    try:
        print "running job : %s "%runner.project_file
        logfile = open(runner.log, 'w')
        prev_handler = signal.signal(signal.SIGALRM, runner.signal_handler)
        signal.alarm(runner.timeout)
        #print runner.cmd
        child = subprocess.Popen("%s" % runner.cmd, stdout= logfile, stderr= logfile, close_fds = True, shell= True, cwd=runner.work_dir)
        
        runner.returncode =  child.wait()
        signal.alarm(0)
    
        logfile  = open(runner.log)
        response = "".join(logfile.readlines())
        logfile.close()
    
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
                runner.summary += "*** Process was killed, since it did not terminate within %u seconds. ***\n" % runner.timeout

    #signal.signal(signal.SIGALRM, runner.prev_handler)
    runner.parse_log()
    runner.post_result(configs['result_url'], configs['api_user'], configs['api_pass'])
    print "Wrapper completed with child status", runner.returncode

    


    
