class Favourite < ActiveRecord::Base
  
  before_save :check_favouritable
  
  before_save :check_duplicate
  
  belongs_to :favouritable, 
             :polymorphic => true
             
  belongs_to :user
  
  validates_presence_of :favouritable_type,
                        :favouritable_id,
                        :user_id
  
  # Finder to get all favourites for a given favouritable.
  scope :for_favouritable, lambda { |favouritable_type, favouritable_id|
    { :conditions => { :favouritable_type =>  favouritable_type, 
                       :favouritable_id => favouritable_id },
      :order => "created_at DESC" }
  }
  
  # Finder to get all favourites by a given user.
  scope :by_user, lambda { |user_id|
    { :conditions => { :user_id => user_id },
      :order => "created_at DESC" }
  }
  
  # Helper class method to look up a favouritable object
  # given the favouritable class name and id 
  def self.find_favouritable(favouritable_type, favouritable_id)
    return nil if favouritable_type.blank? or favouritable_id.blank?
    begin
      return favouritable_type.constantize.find(favouritable_id)
    rescue
      return nil
    end
  end
  
  protected
  
  def check_favouritable
    if Favourite.find_favouritable(self.favouritable_type, self.favouritable_id).nil?
      self.errors.add(:favouritable_id, "doesn't exist")
      return false
    else
      return true
    end
  end
  
  def check_duplicate
    if Favourite.find_by_user_id_and_favouritable_type_and_favouritable_id(self.user_id, self.favouritable_type, self.favouritable_id)
      self.errors.add_to_base("Items cannot be favourited more than once")
      return false
    else
      return true
    end
  end 
  
end
