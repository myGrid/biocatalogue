# BioCatalogue: lib/bio_catalogue/search_by_data.rb
#
# TODO: appropriate copyright statement
#
# Authors: Jerzy Orlowski and Jiten Bhagat
#
# Module for searching the input and output ports based on their example data
# by matching the query data with a set of regular expressions 



module BioCatalogue
  module SearchByData
    require 'libxml'
    require 'cgi'
    
    @@REGEX_FILE_PATH=File.join(RAILS_ROOT,'data','regex.txt')
    @@EXAMPLE_MIN_LENGTH=0
    
    #function for updating the annotation_properties and other tables
    # needed for system to work
    def self.update_annotation_properties_full()
      self.load_regular_expressions()
      self.calculate_annotation_parsed_types()
      self.calculate_annotation_properties_regex(:force=>true)
      ''
    end
    
    #loads /updates regular expressions from a text file
    def self.load_regular_expressions(path=@@REGEX_FILE_PATH)
      f = File.open(path, "r")
      file_regexes={}
      f.each_line do|line|
        line2=line.chop!
        begin
          #check if regular expression is correct (able to compile)
          regex = Regexp.new(line2)
          file_regexes[line2]=1
          if not DataSearchRegex.exists?(:regex_value=>line2)
            d=DataSearchRegex.new(:regex_name=>line2, :regex_value=>line2, :regex_type=>'filequirkqs')
            d.save()
          end
        rescue Exception=>ex
          logger.warn("Incorrect regular experission #{ex.class.name} - #{ex.message}")
          logger.warn(ex.backtrace)
        end  
      end
      #delete from database regular expressions that were deleted from regex file
      database_regexes=DataSearchRegex.find(:all)
      database_regexes.each do |database_regex|
        if file_regexes[database_regex.regex_value]==nil
          database_regex.delete()
        end
      end
      ''
    end   
  
    #calculates / updates annotation parsed types
    def self.calculate_annotation_parsed_types()
      examples_annotations=Annotation.find(:all, :conditions=>["attribute_id=?",5])
      examples_annotations.each do |annotation|
        type=self.calculate_annotation_parsed_type(annotation)
        annotation.create_annotation_parsed_type(attributes={:parsed_type=>type})
      end
    end
    
   #caluculates the parsed type of an annotation for example inputs and outputs
   #this should be basically one of "text","xml","binary"  
    def self.calculate_annotation_parsed_type(annotation)
      return "text"
    end
    
    
    #update the annotation_properties tables
    #if force=false then existing values are not recalculated
    def self.calculate_annotation_properties_regex(force=false)
      annotations = Annotation.find(:all,
        :joins => [ :annotation_parsed_type, :attribute ],
        :conditions => [ "annotation_attributes.name = ? AND annotation_parsed_types.parsed_type= ? AND CHAR_LENGTH(annotations.value)>=?","Example","text",@@EXAMPLE_MIN_LENGTH ])
      regexes=DataSearchRegex.find(:all)
      regexes2=[]
      #precompile all the regular expressions so as not to do it in a loop
      regexes.each do |regex|
        regexes2 << [regex,Regexp.new(regex.regex_value)]
      end
      #for each annotation and regex check a match
      #store only positive values
      annotations.each do |annotation|
        regexes2.each do |regex2|
          regex_result=regex2[1].match(annotation.value)        
          property = AnnotationProperty.find(:first,
            :conditions => [ "annotation_id = ? AND property_type=? AND property_id=?",annotation.id,"DataSearchRegex",regex2[0].id ])
          if property==nil
            if regex_result
              property=AnnotationProperty.new(:annotation=>annotation,:property=>regex2[0],:value=>0)
              property.value=1
              property.save()
            end
          else
            if force
              property.value=regex_result ? 1 : 0
              if property.value==1:
               property.save()
              else
                property.destroy
              end
            end
          end
        end 
      end
    end
    
    # get the annotations ids of example values for SoapInput/Output Ports
    # that are similar to user data given a state of annotation_properties table)
    # method uses precalculated (or cached) state of the database
    def self.get_matching_ports_for_data_properties(data,database_positive_properties,limit=50)
      data=data.to_s()
      regexes=DataSearchRegex.find(:all)
      regex_number=regexes.length
      
      #hash that stores annotations matching each regex
      database_positive_properties_by_regex={}
      
      #result hash that stores scores for each annotation as a list
      #column 0 - number of regexes matching annotation
      #column 1 - number of regexes mathing both query data and annotation  
      result_scores_by_annotation={}
      
      #calculate database_positive_properties_by_regex
      #and fill results score with number of regexes matching each annotation
      regexes.each do |regex|
        database_positive_properties_by_regex[regex.id]=[]
      end  
      database_positive_properties.each do |property|
        database_positive_properties_for_regex=database_positive_properties_by_regex[property.property_id]
        if database_positive_properties_for_regex!=nil
          database_positive_properties_for_regex << property.annotation_id
        end     
   
        result_score_for_annotation=result_scores_by_annotation[property.annotation_id]
        if result_score_for_annotation==nil:
          result_score_for_annotation=[0,0]
        end
        result_score_for_annotation[0]+=1
        result_scores_by_annotation[property.annotation_id]=result_score_for_annotation
      end
      
      
      #hash with keys that are ids of regexes mathing user data
      user_data_positive_regex_results=calculate_positive_regex_result(data,regexes)
      
      #number of regexes matching user query
      number_of_regexes_matching_query=user_data_positive_regex_results.keys.length
      
      #fill results score with number of regexes matching both annotations and regexes
      user_data_positive_regex_results.keys.each do |regex_id|
        database_positive_properties_by_regex[regex_id].each do |annotation_id|
          result_scores_by_annotation[annotation_id][1]+=1
        end
      end
      
      #calculate the final score for each annotation
      scores={}
      for annotation_id in result_scores_by_annotation.keys do
        result=result_scores_by_annotation[annotation_id]
        scores[annotation_id]=1.0+(2*result[1]-result[0]-number_of_regexes_matching_query+0.0)/regex_number
      end
      scores_sorted=scores.sort { |l, r| l[1]<=>r[1] }
      
      final_result=UserDataMatchResults.new(scores_sorted.reverse,limit=limit)
    end
    
    
    # get the positive regex result for each input example
    # method might be used (in future) for caching
    def self.get_database_positive_properties_input()
      database_positive_properties=AnnotationProperty.find(:all,
        :joins => [ :annotation],
        :conditions => [ "annotations.annotatable_type = ? AND annotation_properties.property_type= ? AND annotation_properties.value=? AND CHAR_LENGTH(annotations.value)>=?","SoapInput","DataSearchRegex","1",@@EXAMPLE_MIN_LENGTH ])
      return  database_positive_properties
    end

    # get the positive regex result for each output example
    # method might be used (in future) for caching
    def self.get_database_positive_properties_output()
      database_positive_properties=AnnotationProperty.find(:all,
        :joins => [ :annotation],
        :conditions => [ "annotations.annotatable_type = ? AND annotation_properties.property_type= ? AND annotation_properties.value=? AND CHAR_LENGTH(annotations.value)>=?","SoapOutput","DataSearchRegex","1",@@EXAMPLE_MIN_LENGTH ])
      return  database_positive_properties
    end

    # get the annotations ids of example values for SoapInput Ports
    # that are similar to user data given a state of annotation_properties table)
    def self.get_matching_input_ports_for_data(data,limit=50)
      aaa= get_matching_ports_for_data_properties(data,get_database_positive_properties_input(),limit)
      return aaa
    end
    
    # get the annotations ids of example values for SoapOutput Ports
    # that are similar to user data given a state of annotation_properties table)
    def self.get_matching_output_ports_for_data(data,limit=50)
      aaa= get_matching_ports_for_data_properties(data,get_database_positive_properties_output(),limit)
      return aaa
    end
    
    # calculate regexes that give positive result on user data
    def self.calculate_positive_regex_result(data,regexes=DataSearchRegex.find(:all))
      data_positive_regex_result={}
      regexes.each do |regex|
        result=Regexp.new(regex.regex_value).match(data)?1:0
        if result==1
          data_positive_regex_result[regex.id]=1
        end
      end
      return data_positive_regex_result
    end
    
    #class for storing and presenting search results
    class UserDataMatchResults
      attr_accessor :all_items
      
      def initialize(match_result, limit=50)
        @all_items = [ ]
        annotation_scores = match_result[0..limit-1]
        annotation_scores.each do |annotation_score|
          @all_items << UserDataMatchResultItem.new(annotation_score[0])  
        end
      end
      
      def paged_results(page, num_per_page)
        @all_items.paginate(:page => page, :per_page => num_per_page)
      end
    
      def to_s
        @all_items.inspect
      end
    end
    
    class UserDataMatchResultItem
      def initialize(annotation_id)
        @annotation_id = annotation_id
      end
      
      def annotation
        @annotation ||= Annotation.find_by_id(@annotation_id)
      end
      
      def port
        @port ||= self.annotation.annotatable
      end
      
      def operation
        @operation ||= self.port.soap_operation
      end
      
      def service
        @service = self.operation.soap_service.service
      end
    
      def to_s
        "%d" %(@annotation_id) 
      end
    end
    
  end
end
