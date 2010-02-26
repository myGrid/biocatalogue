
from xml.dom.minidom import parse

class ScriptListingReader:
    
    def __init__(self, filename):
        self.filename = filename
    
    def parse(self):
        dom = parse(self.filename)
        scripts  = self.handle_scripts(dom)
        projects = self.handle_soapui(dom)
        
        return [scripts, projects]
    
    
    # List of test scripts in this configuration
    def handle_scripts(self, dom):
        nodeList = []
        test_scripts = dom.getElementsByTagName('scripts')
        for script in test_scripts:
            nodeList = script.getElementsByTagName('script')
        scriptList = self.handle_script(nodeList)
        
        return scriptList
    
    # List of soapUI projects in this configuration
    def handle_soapui(self, dom):
        nodeList = []
        test_scripts = dom.getElementsByTagName('soapui')
        for script in test_scripts:
            nodeList = script.getElementsByTagName('project')
        projectList = self.handle_script(nodeList)
        
        return projectList
    
    def handle_script(self, script_node_list):
        configs = []
        for node in script_node_list:
            service_id   = self.get_text(node.getElementsByTagName('service_id')[0].childNodes).strip()
            test_id      = self.get_text(node.getElementsByTagName('test_id')[0].childNodes).strip()
            executable   = self.get_text(node.getElementsByTagName('executable')[0].childNodes).strip()
            configs.append((int(service_id), int(test_id), executable))
        
        return configs
    
    def get_text(self, node_list):
        rc = ""
        for node in node_list:
            if node.nodeType == node.TEXT_NODE:
                rc = rc + node.data
        return rc
    
if __name__ == "__main__":
    queue = ScriptListingReader('../config/script_listing.xml').parse()
    print "Queuing Test Scripts", "\nQueuing ".join(["%s/%s/package/%s" % values for values in queue[0]])
    print "\n-----------------------------------------------------\n"
    print "Queuing SoapUI Projects", "\nQueuing ".join(["%s/%s/package/%s" % values for values in queue[1]])
    