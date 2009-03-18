require 'uri'


module BioCatalogue
  module OnLookerHelper
    
    def OnLookerHelper.get_host(url)
      URI.parse(url).host   
    end
    
    # determine weather it is a domain name
    # or ip address
    def OnLookerHelper.get_host_type(host)
      if host.split('.')[0].to_i == 0
        'web'
      else
        'ip'
      end
    end
    
  end
end