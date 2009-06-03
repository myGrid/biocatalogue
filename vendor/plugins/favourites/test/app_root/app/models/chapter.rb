class Chapter < ActiveRecord::Base
  acts_as_favouritable
  
  belongs_to :book
end