# requires the ContentBlob model to store the
# binary data of the uploaded test file

class ServiceTest < ActiveRecord::Base
  belongs_to :testable, :polymorphic => true
  
  #test results
  has_many :test_results, :as => :test, :dependent => :destroy  

  # NOTE: Tests belong to a user
  belongs_to :user
  belongs_to :content_blob, :dependent => :destroy
  
  #validations 
  validates_associated :content_blob
  validates_presence_of :name, :exec_name, 
                        #:description, :content_blob_id,
                        :filename, :content_type
  validates_inclusion_of :binding, :in  => %(perl python java ruby ), 
                                    :message => "please select a binding"
                        
  attr_protected :filename, 
                 :content_type
                  
  # Helper class method to lookup all comments assigned
  # to all testable types for a given user.
  def self.find_tests_by_user(user)
    find(:all,
      :conditions => ["user_id = ?", user.id],
      :order => "created_at DESC"
    )
  end
  
  # Helper class method to look up all tests for 
  # testable class name and testable id.
  def self.find_tests_for_testable(testable_str, testable_id)
    find(:all,
      :conditions => ["testable_type = ? and testable_id = ?", testable_str, testable_id],
      :order => "created_at DESC"
    )
  end

  # Helper class method to look up a testable object
  # given the testable class name and id 
  def self.find_testable(testable_str, testable_id)
    testable_str.constantize.find(testable_id)
  end
  
  
  #create an entry into the content_blobs table
  #containing the binary data of the uploaded file
  def test_data=(incoming_file)
    begin
      self.filename = incoming_file.original_filename
      self.content_type = incoming_file.content_type
      self.content_blob = ContentBlob.new({:data => incoming_file.read})
    rescue Exception => ex
      errors.add_to_base("Error uploading file: #{ex.backtrace.join("\n")}")
    end
  end
 
#  def filename=(new_filename)
#    write_attribute("filename", sanitize_filename(new_filename))
#  end
# 
#  private
#  def sanitize_filename(filename)
#    #get only the filename, not the whole path (from IE)
#    just_filename = File.basename(filename)
#    #replace all non-alphanumeric, underscore or periods with underscores
#    just_filename.gsub(/[^\w\.\-]/, '_')
#  end

  
end