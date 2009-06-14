# BioCatalogue: lib/bio_catalogue/categories.rb
#
# Copyright (c) 2009, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

# Module to carry out the bulk of the logic for categorising of services.

module BioCatalogue
  module Categorising
    
    # Goes through the service_categories data and loads them all up into the db 
    # if not already in, or loads new categories or updates existing categories.
    def self.load_data
      begin
        Category.transaction do
          categories_data = YAML.load(IO.read(File.join(Rails.root, 'data', 'service_categories.yml')))
          process_node(categories_data)
        end
      rescue Exception => ex
        msg = "Could not load up Categories data. Error message: #{ex.message}. Running db:migrate might solve this problem."
        Rails.logger.error(msg)
        puts(msg)
      end
    end
    
    def self.get_categories_for_service(service)
      categories = [ ]
      
      anns = service.annotations_with_attribute("category")
      
      category_ids = anns.map{|a| a.value.to_i}
      
      category_ids.each do |category_id|
        c = Category.find(:first, :conditions => { :id => category_id })
        categories << c unless c.nil?
      end
      
      return categories
    end
    
    def self.user_created_category?(service, category_id, user)
      anns = service.annotations_with_attribute_and_by_source("category", user)
      if anns.blank?
        return false
      else
        return anns.map{|a| a.value}.include?(category_id.to_s)
      end
    end
    
    protected
    
    def self.process_node(node, current_parent_id=nil)
      node.each do |key, values|
        parent_id, parent_name = split_raw_category(key)
        process_category(parent_id, parent_name, current_parent_id)
        unless values.nil?
          case values
            when Array
              values.each do |child|
                id, name = split_raw_category(child)
                process_category(id, name, parent_id)
              end
            when Hash
              new_current_parent_id = parent_id
              process_node(values, new_current_parent_id)
          end
        end
      end
    end
    
    def self.split_raw_category(c)
      id = ""
      name = ""
      
      name, id = c.split('[')
      name.strip!
      id = id.gsub(']', '').to_i
      
      return [ id, name ]
    end
    
    def self.process_category(id, name, parent_id=nil)
      if (category = Category.find_by_id(id)).nil?
        Util.say("Adding new category to database: '#{name}' (ID: #{id}; Parent ID: #{parent_id})")
        Category.new do |c| 
          c.id = id
          c.name = name
          c.parent_id = parent_id
          c.save
        end
      else
        if category.name != name or category.parent_id != parent_id
          Util.say("Updating category in database: '#{name}' (ID: #{id}; Parent ID: #{parent_id})")
          category.name = name
          category.parent_id = parent_id
          category.save
        end
        category
      end
    end
    
  end
end