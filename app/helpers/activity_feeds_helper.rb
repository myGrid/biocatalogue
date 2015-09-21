# BioCatalogue: app/helpers/application_helper.rb
#
# Copyright (c) 2009-2010, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details.

# Methods added to this helper will be available to all templates in the application.

module ActivityFeedsHelper
  
  include ApplicationHelper
  
  # Returns something like:
  #   [ { "Today" => [ [ "text", :service, DateTime ], [ ... ], ... ] },
  #     { "Yesterday" => [ [ "text", :user, DateTime ], [ ... ], ... ] },
  #     { "4 weeks ago" => [ [ "text", :annotation, DateTime ], [ ... ], ... ] } ] 
  #
  # Style can be :simple or :detailed
  def activity_entries_for(activity_logs, style=:simple)
    allowed_models_to_process = ["User", "Service", "Annotation", "SoapServiceChange", "Favourite", "ServiceTest"].freeze
    
    return [ ] if activity_logs.blank?
    
    results = [ ]
    
    # Get object cache for these activity_logs
    object_cache = BioCatalogue::ActivityFeeds.build_object_cache_for(activity_logs)

    # We need to consider ordering of the grouped events!
    
    days_order = [ ]
      
    benchmark "Set up days_order (for the ordering of the grouped events)" do
    
      activity_logs.map { |a| a.created_at }.each do |d|
        c = classify_time_span(d, style)
        days_order << c unless days_order.include?(c)
      end
      
    end
  
    temp_results = Hash.new { |h,k| h[k] = [ ] }
    
    benchmark "Preparing the activity feed entries" do
    
      # Now prepare the entries    
      activity_logs.each do |al|
        if allowed_models_to_process.include?(al.activity_loggable_type)
          entry_obj = get_object_via_cache(al.activity_loggable_type, al.activity_loggable_id, object_cache)
          
          if entry_obj.nil?
            entry_text = ''
            entry_type = ''
          else
            entry_text, entry_type = activity_feed_entry_for(entry_obj, al, style, object_cache)
          end
          
          data = [ entry_text, entry_type, al.created_at ]
          
          if entry_text.blank?
            BioCatalogue::Util.say "Activity feed entry was blank for ActivityLog record: \n\t#{al.inspect}.\n It could be that the activity_loggable, culprit or referenced has been deleted or deactivated."
          else
            temp_results[classify_time_span(al.created_at, style)] << data
          end
        end
      end
    
    end
    
    days_order.each do |d|
      results << { d => temp_results[d] } unless temp_results[d].blank?
    end
    
    return results
  end
  
  protected
  
  def activity_feed_entry_for(item, activity_log, style, object_cache={})
    return "" if item.nil?
    
    action = activity_log.action
    extra_data = activity_log.data
      
    output = ""
    entry_type = item.class.name.underscore.to_sym
    
    begin
      case item
        when User
          
          case action
            
            when 'activate'
              # Check if user is still activated
              if item.activated?
                output << link_to(display_name(item), item)
                output << content_tag(:span, " joined", :class => "activity_feed_action")
                output << " #{SITE_NAME}"
              end
              
          end
          
        when Service
          
          case action
            
            when 'create'
              submitter = get_object_via_cache(item.submitter_type, item.submitter_id, object_cache)
              
              unless submitter.nil?
                output << link_to(display_name(submitter), submitter)
                output << content_tag(:span, " registered", :class => "activity_feed_action")
                output << " a new Service: "
                output << link_to(display_name(item), item)
              end
            
            when 'archive', 'unarchive'
              culprit = get_object_via_cache(activity_log.culprit_type, activity_log.culprit_id, object_cache)
              
              unless culprit.nil?
                output << link_to(display_name(culprit), culprit)
                output << content_tag(:span, " #{action}d", :class => "activity_feed_action")
                output << " the Service: "
                output << link_to(display_name(item), item)
              end
            
              
          end
          
        when Annotation
          
          case action
            
            when 'create'
              annotatable = get_object_via_cache(item.annotatable_type, item.annotatable_id, object_cache)
              source = get_object_via_cache(item.source_type, item.source_id, object_cache)
              value_to_display = item.value_content
              
              # Special case for annotation values for certain kinds of attributes
              if item.attribute_name.downcase == "tag"
                namespace, fragment = BioCatalogue::Tags.split_ontology_term_uri(item.value.name)
                value_to_display = item.value.label
              end
              
              unless value_to_display.blank? or item.attribute.nil? or annotatable.nil? or source.nil?
                inner_obj_text = case item.annotatable_type
                  when "ServiceDeployment", "SoapService", "RestService"
                    "the #{item.annotatable_type.titleize} of "
                  else
                    nil
                end
                
                subject_type = case item.annotatable_type
                  when "Service", "ServiceDeployment", "ServiceVersion", "SoapService", "RestService"
                    "Service"
                  else
                    item.annotatable_type.titleize
                end
                
                subject = case item.annotatable_type
                  when "ServiceDeployment", "ServiceVersion", "SoapService", "RestService"
                    item.annotatable.service
                  else
                    item.annotatable
                end
              
                output << link_to(display_name(source), source)
                output << content_tag(:span, " added", :class => "activity_feed_action")
                output << " a #{h(item.attribute_name.humanize.downcase)} annotation to "
                output << inner_obj_text unless inner_obj_text.blank?
                output << "#{subject_type}: "
                
                link = link_for_web_interface(subject)
                
                output << (link || display_name(subject))
                
                #if style == :detailed
                #  output << " - "
                #  output << content_tag(:div, :class => "box_annotations", :style => "margin-top: 0.1em;") do
                #    rounded_html(annotation_text_item_background_color, "#333", "99%") do
                #      x = '<div class="text">'
                #      x << annotation_prepare_description(value_to_display, {:do_strip_tags => true,
                #                                                                               :truncate_length=>100,
                #                                                                               :do_auto_link => false,
                #                                                                               :do_simple_format => false,
                #                                                                               :do_white_list => true,
                #                                                                               :is_markdownable => true
                #      })
                #      x << '</div>'
                #      x
                #    end
                #  end
                #end
              end
              
          end
        
        when SoapServiceChange
          
          case action
            
            when 'create'
              soap_service = get_object_via_cache("SoapService", item.soap_service_id, object_cache)
              
              unless soap_service.service.nil? 
                output << link_to(display_name(soap_service.service), soap_service.service)
                output << " has been"
                output << content_tag(:span, " updated", :class => "activity_feed_action")
                output << " (#{pluralize(item.changelog.length, 'update')} from latest WSDL)."
                output << " See #{link_to("changelog entry", service_url(soap_service.service, :anchor => "updates_from_wsdl_" + item.id.to_s))}."
              end
              
          end
        
        when Favourite
          
          case action
            
            when 'create'
              obj_favourited = get_object_via_cache(item.favouritable_type, item.favouritable_id, object_cache)
              
              user = get_object_via_cache("User", item.user_id, object_cache)
              
              unless obj_favourited.nil? or user.nil?
                output << link_to(display_name(user), user)
                output << content_tag(:span, " favourited", :class => "activity_feed_action")
                output << " the #{item.favouritable_type.titleize}: "
                output << link_to(display_name(obj_favourited), obj_favourited)
              end
          
          end
        
        when ServiceTest  
          
          case action
            
            when 'status_change'
              service = get_object_via_cache("Service", item.service_id, object_cache)

              unless service.nil?
                current_result = TestResult.find_by_id(extra_data['current_result_id'])
                previous_result = TestResult.find_by_id(extra_data['previous_result_id']) || TestResult.new_with_unknown_status
                
                entry_type = "monitoring_status_change_unknown"
                
                unless current_result.nil?
                  current_status = BioCatalogue::Monitoring::TestResultStatus.new(current_result)
                  previous_status = BioCatalogue::Monitoring::TestResultStatus.new(previous_result)
                  
                  output << link_to(display_name(service), service_url(service))
                  output << " has a test "
                  output << content_tag(:span, "change status", :class => "activity_feed_action")
                  output << " from #{previous_status.label} to <b>#{current_status.label}</b>"
                  
                  entry_type = "monitoring_status_change_#{current_status.label.downcase}".to_sym
                end
                  
              end
          
          end
        
      end
    rescue Exception => ex
      BioCatalogue::Util.log_exception(ex, :error, "Failed to run 'ActivityFeedsHelper#activity_feed_entry_for' for item: #{item.class.name} #{item.id}, action: #{action}, style: #{style}.")
      output = ''
    end
    
    return [ output, entry_type ]
  end
  
  def get_object_via_cache(obj_type, obj_id, object_cache)
    return object_cache[obj_type][obj_id.to_s] if object_cache[obj_type].has_key?(obj_id.to_s)
    return obj_type.constantize.find_by_id(obj_id)
  end
  
end