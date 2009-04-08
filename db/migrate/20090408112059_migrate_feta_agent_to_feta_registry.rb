class MigrateFetaAgentToFetaRegistry < ActiveRecord::Migration
  def self.up
    feta_registry = Registry.create(:name => "feta", 
                                    :display_name => "Feta",
                                    :homepage => "http://www.mygrid.org.uk/feta/")
    
    # Some annotations, services, service versions and service deployments 
    # may have been created with the feta Agent as "source" or "submitter".
    # Need to change these and then delete the feta Agent once and for all!
    
    feta_agent = Agent.find_by_name("feta_importer")
    
    unless feta_agent.nil?
      execute 'UPDATE annotations 
               SET source_type = "Registry", source_id = "' + feta_registry.id.to_s + '" 
               WHERE source_type = "Agent" AND source_id = "' + feta_agent.id.to_s + '"'
               
      execute 'UPDATE services 
               SET submitter_type = "Registry", submitter_id = "' + feta_registry.id.to_s + '" 
               WHERE submitter_type = "Agent" AND submitter_id = "' + feta_agent.id.to_s + '"'
               
      execute 'UPDATE service_versions
               SET submitter_type = "Registry", submitter_id = "' + feta_registry.id.to_s + '" 
               WHERE submitter_type = "Agent" AND submitter_id = "' + feta_agent.id.to_s + '"'
               
      execute 'UPDATE service_deployments
               SET submitter_type = "Registry", submitter_id = "' + feta_registry.id.to_s + '" 
               WHERE submitter_type = "Agent" AND submitter_id = "' + feta_agent.id.to_s + '"'
      
      feta_agent.destroy   
    end
  end

  def self.down
    feta_registry = Registry.find_by_name("feta")
    feta_agent = Agent.create(:name => "feta_importer", :display_name => "Feta Importer Agent")
    
    unless feta_registry.nil?
      execute 'UPDATE annotations 
               SET source_type = "Agent", source_id = "' + feta_agent.id.to_s + '" 
               WHERE source_type = "Registry" AND source_id = "' + feta_registry.id.to_s + '"'
               
      execute 'UPDATE services 
               SET submitter_type = "Agent", submitter_id = "' + feta_agent.id.to_s + '" 
               WHERE submitter_type = "Registry" AND submitter_id = "' + feta_registry.id.to_s + '"'
               
      execute 'UPDATE service_versions
               SET submitter_type = "Agent", submitter_id = "' + feta_agent.id.to_s + '" 
               WHERE submitter_type = "Registry" AND submitter_id = "' + feta_registry.id.to_s + '"'
               
      execute 'UPDATE service_deployments
               SET submitter_type = "Agent", submitter_id = "' + feta_agent.id.to_s + '" 
               WHERE submitter_type = "Registry" AND submitter_id = "' + feta_registry.id.to_s + '"'
      
      feta_registry.destroy
    end
  end
end
