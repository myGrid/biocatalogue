class Book < ActiveRecord::Base
  acts_as_favouritable
  
  has_many :chapters
end