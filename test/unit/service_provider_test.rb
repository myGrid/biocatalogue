require 'test_helper'

class ServiceProviderTest < ActiveSupport::TestCase

  def test_merge_into
    x = create_rest_service(:base_endpoint => "http://x.example.com")
    x_sp = x.service.latest_deployment.provider
    x_sp_id = x_sp.id 
    
    y = create_rest_service(:base_endpoint => "http://y.example.com")
    y_sp = y.service.latest_deployment.provider
    y_sp_id = y_sp.id     
    
    assert_equal x_sp.service_provider_hostnames.size, 1
    assert_equal y_sp.service_provider_hostnames.size, 1
    assert_equal x_sp.service_deployments.size, 1
    assert_equal y_sp.service_deployments.size, 1
    assert x_sp.annotations.empty?
    assert y_sp.annotations.empty?
    
    assert x_sp.merge_into(y_sp)                    

    y = ServiceProvider.find(y_sp_id)
    
    assert_equal y_sp.service_provider_hostnames.size, 2
    assert_equal y_sp.service_deployments.size, 2
    assert y_sp.annotations.empty?
    
    y_sp.destroy
  end
end
