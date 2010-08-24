# BioCatalogue: app/controllers/responsibility_requests_controller.rb
#
# Copyright (c) 2010, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details.

class ResponsibilityRequestsController < ApplicationController
  
  before_filter :login_or_oauth_required, :only => [ :create, :index, :show, 
                                            :destroy, :new, :approve ]
  before_filter :find_request, :only => [ :approve, :destroy, :deny, :turn_down, :cancel ]
  before_filter :find_service, :only => [ :new ]
  before_filter :find_requests, :only => [ :index ]
  before_filter :authorise, :only => [ :destroy, :cancel ]
  before_filter :authorise_approval, :only => [ :approve ]
  before_filter :authorise_create , :only => [ :create ]
  
  if ENABLE_SSL && Rails.env.production?
    ssl_required :all
  end

  # GET /responsibility_requests
  # GET /responsibility_requests.xml
  def index
    
    respond_to do |format|
      format.html #
      format.xml {disable_action}
    end
  end

  # GET /responsibility_requests/new
  # GET /responsibility_requests/new.xml
  def new
    @responsibility_request = ResponsibilityRequest.new
    
    respond_to do |format|
      format.html #
      format.xml {disable_action}
    end
  end
  
  # POST /responsibility_requests
  # POST /responsibility_requests.xml
  def create
    @responsibility_request = ResponsibilityRequest.new(params[:responsibility_request])
    @service = Service.find(params[:responsibility_request][:subject_id])
    
    respond_to do |format|
      if @responsibility_request.save
        flash[:notice] = "You request was successfully received"
        
        # mail those responsible
        Delayed::Job.enqueue(BioCatalogue::Jobs::ServiceOwnerRequestNotification.new(@service.all_responsibles,
                                                                                      base_host, @service, current_user ))
        # Send confirmation mail to user
        # logger.info("Sending confirmation mail to requester: #{current_user.email}")
        Delayed::Job.enqueue(BioCatalogue::Jobs::ServiceClaimantRequestNotification.new(current_user, base_host, @service))
      
        format.html { redirect_to(@service) }
        format.xml {disable_action}
      else
        flash[:error] = "Could not process your request"
        format.html { redirect_to(@service) }
        format.xml {disable_action}
      end
    end
  end


  # DELETE /responsibility_requests
  # DELETE /responsibility_requests.xml
  def destroy
    
    respond_to do |format|
      if @req.destroy
        flash[:notice] = "Responsibility request with id : '#{@req.id}' has been cancelled"
        format.html { redirect_to responsibility_requests_url }
        format.xml  { head :ok }
      else
        flash[:error] = "Failed to cancel responsibility request '#{@req.id}'"
        format.html { redirect_to service_url(@service) }
      end
    end
  end
  
  def cancel
    respond_to do |format|
      if @req.cancel!(current_user)
        flash[:notice] = "Responsibility request has been cancelled"
        
        # notify responsible(s) about cancellation
        Delayed::Job.enqueue(BioCatalogue::Jobs::ServiceResponsibilityRequestCancellation.new( @service.all_responsibles, 
                                                                                                  base_host, @service, current_user, @req))
        format.html { redirect_to responsibility_requests_url }
        format.xml  { head :ok }
      else
        flash[:error] = "Failed to cancel responsibility request "
        format.html { redirect_to service_url(@service) }
      end
    end
  end
  
  def approve
    respond_to do |format|
      message ="Approving... "
      if @req.user_can_approve(current_user)
        if @req.approve!(current_user)
          message = message + " approved!"
          to_be_informed = @service.all_responsibles.dup
          to_be_informed << @req.user
          Delayed::Job.enqueue(BioCatalogue::Jobs::ServiceResponsibilityRequestApproval.new(to_be_informed, 
                                                                                            base_host, @service, current_user, @req))                                                                                          
        else
            message = message + " There was a problem approving this request!"
        end
      else
        message = message + " You are not allowed to perform this action!"
      end
        flash[:notice] = message
        format.html {redirect_to  responsibility_requests_url }#
        format.xml {disable_action}
    end
  end
  
  def turn_down
    respond_to do |format|
      format.html{ render :partial => 'deny_responsibility', 
                                :layout =>'application_wide', :locals => {:resp_request => @req}}
      format.xml {disable_action}
    end
  end
   
  def deny
    @req.message = params[:responsibility_request][:message]
    respond_to do |format|
      message ="Turning down this request... "
        if @req.user_can_approve(current_user)
          if @req.turn_down!(current_user)
            message = message + " Done!"
            Delayed::Job.enqueue(BioCatalogue::Jobs::ServiceResponsibilityRequestRefusal.new(@service.all_responsibles, 
                                                                                                base_host, current_user, @req))                                                                                              
          else
            message = message + " There was a problem while turning down this request!"
          end
        else
          message = message + " You are not allowed to perform this action!"
        end
 
      flash[:notice] = message
      format.html { redirect_to responsibility_requests_url }
      format.xml {disable_action}
    end
  end

  private

  def find_service
    @service = Service.find(params[:service_id])
  end
  
  def find_request
    @req     = ResponsibilityRequest.find(params[:id])
    @service = @req.subject
  end
  
  def authorise
    @req = ResponsibilityRequest.find(params[:id])
    unless is_admin? || current_user == @req.user
      flash[:error] = "You are not allowed to perform this action"
      redirect_to responsibility_requests_url
    end
    return true
  end
  
  # filter request to only those which user can approve or own
  def find_requests
    @responsibility_requests = ResponsibilityRequest.paginate(:page => @page,
                                  :per_page => @per_page,
                                  :conditions => "status='pending' OR status IS NULL")
                                  
    @responsibility_requests.delete_if{|r| !r.user_can_approve(current_user) && (r.user != current_user) }
  end
  

  def authorise_approval
    @service = ResponsibilityRequest.find(params[:id]).subject
    unless logged_in? && BioCatalogue::Auth.allow_user_to_curate_thing?(current_user, @service)
      flash[:error] = "You are not allowed to perform this action"
      redirect_to responsibility_requests_url
    end
    return true
  end
  
  def authorise_create(limit=5)
    service = Service.find(params[:responsibility_request][:subject_id])
    req = ResponsibilityRequest.find(:first, :conditions => {:user_id => current_user.id,
                                                          :subject_id => service.id,
                                                          :subject_type => service.class.name })
    pending = ResponsibilityRequest.find(:all, :conditions => ["user_id=? AND status = ? ", current_user.id, 'pending']).first(limit)
    if req || pending.count == limit
      msg = "<p> You are not allowed to perform this action. You have reached your limit of #{limit} pending requests. </p>"
      msg = msg + "Please <a href='#{SITE_BASE_HOST}/contact'> contact</a> BioCatalogue for further assistance. "
      flash[:error] = msg
      redirect_to service_url(service)
    end
  end
  
end
