
class ConfigReader:
    def __init__(self, config_file):
        self.config = config_file
        
    def read(self):
        #print "Reading the config file"
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