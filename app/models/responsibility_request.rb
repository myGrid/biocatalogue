# BioCatalogue: app/models/responsibility_request.rb
#
# Copyright (c) 2010, University of Manchester, The European Bioinformatics
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

class ResponsibilityRequest < ActiveRecord::Base
  belongs_to :user
  belongs_to :subject, :polymorphic => true
  
  validates_presence_of :user_id
  validates_presence_of :subject_id
  validates_presence_of :subject_type
  validates_existence_of :user
  validates_existence_of :subject
  
  if ENABLE_TRASHING
    acts_as_trashable
  end
  
  if USE_EVENT_LOG
    acts_as_activity_logged(:models => { :culprit => { :model => :user } })
  end
  
  def user_can_approve(user)
    self.subject.all_responsibles.include?(user) 
  end
  
  def approval_pending?
    self.activated_at.nil? && self.status='pending'
  end
  
  def approve!(approver)
    if self.approval_pending?
      begin
        self.activated_at = Time.now
        self.activated_by = approver.id
        self.status ="approved"
        self.save! if ServiceResponsible.add(self.user_id, self.subject.id)
        return true
      rescue Exception => ex
        logger.error("ERROR: Failed to approve, responsibility request #{self.id}  ")
        logger.error(ex)
        return false
      end
    else
      logger.error("ERROR: responsibility request #{self.id} already approved ")
      return false
    end
  end
  
  def turn_down!(user)
    if self.approval_pending?
      begin
        self.activated_at = Time.now
        self.activated_by = user.id
        self.status ="denied"
        self.save!
        return true
      rescue Exception => ex
        logger.error("ERROR: Failed to turn_down, responsibility request #{self.id}  ")
        logger.error(ex)
        return false
      end
    else
      logger.error("ERROR: responsibility request #{self.id} already approved ")
      return false
    end
  end
  
  def cancel!(user)
    if self.approval_pending?
      begin
        self.activated_at = Time.now
        self.activated_by = user.id
        self.status ="cancelled"
        self.save!
        return true
      rescue Exception => ex
        logger.error("ERROR: Failed to cancel, responsibility request #{self.id}  ")
        logger.error(ex)
        return false
      end
    else
      logger.error("ERROR: responsibility request #{self.id} has already been approved! ")
      return false
    end
    
  end
  
end
