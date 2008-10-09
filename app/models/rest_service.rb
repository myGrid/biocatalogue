class RestService < ActiveRecord::Base
  acts_as_trashable
  
  has_many :annotations, :as => :annotatable
end
