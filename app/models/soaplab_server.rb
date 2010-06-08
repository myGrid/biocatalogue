# BioCatalogue: app/models/soaplab_server.rb
#
# Copyright (c) 2008, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

require 'open-uri'
require 'soap/wsdlDriver'
require 'ftools'

class SoaplabServer < ActiveRecord::Base
  if ENABLE_CACHE_MONEY
    is_cached :repository => $cache
    index :location
  end
  
  acts_as_trashable
  
  acts_as_annotatable
  
  has_many :relationships, :as => :object, :dependent => :destroy

  validates_presence_of :location
  validates_uniqueness_of :location, :message => " for this server seems to exist in BioCatalogue"
  validates_url_format_of :location,
                          :allow_nil => false
  
  if ENABLE_SEARCH
    acts_as_solr(:fields => [ :location ])
  end

  # save the soap services from this server in
  # the database
  def save_services(current_user)
    error_urls        = []
    existing_services = []
    new_wsdls         = []
    server_data       = services_factory().values.flatten
    
    unless server_data.empty?
      server_data.each{ |datum|
         url = datum['location']
         soap_service  = SoapService.new({:wsdl_location => url})
         success, data = soap_service.populate
         dup = SoapService.check_duplicate(url, data["endpoint"])
      if success and dup != nil
         existing_services << dup
         logger.info("This service exists in the database")
      else
        transaction do
          begin
            if success 
              c_success = soap_service.submit_service( data["endpoint"], current_user, {} )  
              if c_success
                new_wsdls << url
                logger.info("Registered service - #{url}. SUCCESS:")
              else
                error_urls << url
                logger.error("post_create failed for service - #{url}. ")
              end
            end
          rescue Exception => ex
            error_urls << url
            logger.error("failed to register service - #{url}. soaplab registration Exception:")
            logger.error(ex)
          end
        end
      end
      }
    end
    create_relationships(new_wsdls)
    create_tags(find_services_in_catalogue(new_wsdls), current_user)
    return [new_wsdls, existing_services, error_urls]
  end
    
  
  #returns data from soaplab1 servers 
  #structure  of data:
  # data = {category_name1 =>[{'name' =>tool_name, 'location' => wsd_url},...],
  #         category_name2 =>[{'name' =>tool_name, 'location' => wsd_url}, ...]  
  #         }
  #
  def get_soaplab1_data(proxy)
    data    = {}
    begin
      categories = proxy.getAvailableCategories()  
      proxy.wiredump_dev = STDERR
      categories.each{|cat| 
        data[cat] = proxy.getAvailableAnalysesInCategory(cat) 
        proxy.wiredump_dev = STDERR
        data[cat].collect! {|a|
          analysis             = {}
          analysis['name']     = a
          analysis['location'] = proxy.getServiceLocation(a)+'?wsdl'
          analysis
          }
      }
      return data
    rescue Exception => ex
      logger.error("Failed to get data from sooaplab server:")
      logger.error(ex)
      return {}
    end
  end


  #get data from soaplab2 server. 
  # TODO : use the getAvailableAnalysesInCategory(cat)
  #        method to get the analysis in each category and remove
  #        the current work around
  # Problems seem to be comming from how ruby handles document literal wsdls
  # with external schemas
  #
  #returns data from soaplab2 servers 
  #structure  of data:
  # data = {category_name1 =>[{'name' =>tool_name, 'location' => wsd_url},...],
  #         category_name2 =>[{'name' =>tool_name, 'location' => wsd_url}, ...]  
  #         }
  #
  def get_soaplab2_data(proxy)
    data  = {}
    begin
      base  = proxy.getServiceLocation("")["return"]
      categories = proxy.getAvailableCategories("")["return"]
      categories.each {|cat| 
        data[cat] = []
        }
      analyses   = proxy.getAvailableAnalyses("")["return"]
      analyses.each{|a|
        datum = {'name'=> a, 'location' => File.join(base, a+'?wsdl') }
        data[a.split('.')[0]]<< datum
      }
      return data
    rescue Exception => ex
      logger.error("Failed to get data from sooaplab server:")
      logger.error(ex)
      return {}
    end
  end
  
  # find all the services in catalogue for this server
  # given the list of wsdls
  def find_services_in_catalogue(wsdls =[])
    return SoapService.find_all_by_wsdl_location(wsdls).collect{ |ss| ss.service }
  end
 
  # the relationship table maps services to a soaplab instance 
  # the emboss subgroup is indicated in the predicate
  def create_relationships(wsdls=[])
    services = find_services_in_catalogue(wsdls)
    services.each{ |service|
    
    relationship = Relationship.new(:subject_type => service.class.to_s,
                                    :subject_id   => service.id, 
                                    :predicate    => "BioCatalogue:memberOf", 
                                    :object_type  => self.class.to_s,
                                    :object_id    => self.id)
    relationship.save!
    }
  end
  
  def create_annotations(annotations_data, source, destination)
    annotations_data.each do |item|
      item.each do |attrib, val|
        unless val.blank?
          anns =[]
          anns << Annotation.new(:attribute_name    => attrib.strip.downcase, 
                                      :value        => val, 
                                      :source_type  => source.class.name, 
                                      :source_id    => source.id,
                                      :annotatable_type => destination.class.name,
                                      :annotatable_id   => destination.id)
          anns.each{ |a| a.save!}
        end
      end
    end
  end
  
  #TODO: Handlers for different deployments of the service
  def create_tags(services, current_user)
    services.each{ |service|
    provider = service.providers.first if service.providers.length == 1
    group_name, name = service.latest_version.service_versionified.wsdl_location.split('/')[-1].split('.')
    create_annotations([{'tag' =>'soaplab'}, {'tag'=> group_name}, {'display_name'=> name.split('?')[0]}], provider, service )
    }   
  end
  
  # based on the url passed, determine how to call the 
  # soaplab interface methods
  def services_factory(url= self.location)
    server_data = {}
    proxy = SOAP::WSDLDriverFactory.new(url).create_rpc_driver
    if url.include?('AnalysisFactory')
      server_data = get_soaplab1_data(proxy)
    else
      server_data = get_soaplab2_data(proxy)
    end
    server_data
  end
  
  # find related objects which are services 
  def services
    related_objects_by_type("Service")
  end
  
  # find a class of objects that are related to the soaplab server
  # e.g. to get all services we would do :  related_services = related_objects_by_type("Service")
  def related_objects_by_type(related_str)
    rels = Relationship.find(:all, :conditions => ["subject_type = ? and object_type = ? and object_id =? ", 
                                                    related_str, self.class.name, self.id] )
    
    related_str.constantize.find(rels.collect{ |r| r.subject_id})
  end
  
  def update_descriptions_from_soaplab!
    self.services.each do |service|
      Delayed::Job.enqueue(BioCatalogue::Jobs::UpdateSoaplabServiceDescription.new(service.id))
    end
  end
   
end
