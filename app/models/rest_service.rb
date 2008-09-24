class RestService < ActiveRecord::Base
  has_many :annotations, :as => :annotatable
end
