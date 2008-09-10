require 'soap/wsdlDriver'

class SoapService < ActiveRecord::Base
  belongs_to :web_service
  has_many :soap_operations
 
  validates_presence_of :name
  validates_presence_of :description
  validates_presence_of :wsdl_location
  
  def get_operations(wsdl_url)
    driver = SOAP::WSDLDriverFactory.new(wsdl_url).create_rpc_driver
    driver.proxy.operation
  end
  
  def save_operations(operations, service)
    for k in operations.keys
      @soap_operation = service.soap_operations.build
      @soap_operation.name = k
      @soap_operation.save
    end
    
  end
  
  def get_inputs(operations)
    puts "Getting inputs"
  end
  
  def get_outputs(operations)
    puts "Getting outputs"
  end
  
end
