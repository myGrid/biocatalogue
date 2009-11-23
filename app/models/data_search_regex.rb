class DataSearchRegex < ActiveRecord::Base
  has_many :annotation_property, :as =>:property_type, :dependent=>:destroy
  
  validates_presence_of :regex_value, :regex_type
end
