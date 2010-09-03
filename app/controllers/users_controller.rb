# BioCatalogue: app/controllers/users_controller.rb
#
# Copyright (c) 2008-2010, University of Manchester, The European Bioinformatics
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details.

class UsersController < ApplicationController

  before_filter :disable_action, :only => [ :destroy ]
  before_filter :disable_action_for_api, :except => [ :index, :show, :annotations_by, :services, :filters, :filtered_index, :saved_searches ]

  before_filter :login_or_oauth_required, :except => [ :index, :new, :create, :show, :activate_account, :forgot_password, 
                                                       :request_reset_password, :reset_password, :rpx_merge_setup, :annotations_by, 
                                                       :services, :filtered_index, :filters ]

  before_filter :check_user_rights, :only => [ :edit, :update, :destroy, :change_password, :saved_searches ]
  
  before_filter :initialise_updated_user, :only => [ :edit, :update ]
  
  skip_before_filter :verify_authenticity_token, :only => [ :rpx_update ]

  before_filter :parse_filtered_index_params, :only => :filtered_index
  
  before_filter :parse_current_filters, :only => [ :index, :filtered_index ]
  
  before_filter :get_filter_groups, :only => [ :filters ]
  
  before_filter :parse_sort_params, :only => [ :index, :filtered_index ]
  
  before_filter :find_users, :only => [ :index, :filtered_index ]
  
  before_filter :find_user, :only => [ :show, :edit, :update, :change_password, :rpx_update, :annotations_by ]
  
  before_filter :add_use_tab_cookie_to_session, :only => [ :show ]

  oauth_authorize :saved_searches

  if ENABLE_SSL && Rails.env.production?
    ssl_required :new, :create, :edit, :update, :activate_account, :forgot_password, :request_reset_password, 
                 :reset_password, :change_password, :rpx_merge_setup, :rpx_merge, :rpx_update, :saved_searches
  end

  # GET /users
  # GET /users.xml
  def index
    respond_to do |format|
      format.html # index.html.erb
      format.xml  # index.xml.builder
      format.json { render :json => BioCatalogue::Api::Json.index("users", json_api_params, @users).to_json }
      format.bljson { render :json => BioCatalogue::Api::Bljson.index("users", @users).to_json }
    end
  end
  
  # POST /filtered_index
  # Example Input (differs based on available filters):
  #
  # { 
  #   :filters => { 
  #     :p => [ 67, 23 ], 
  #     :tag => [ "database" ], 
  #     :c => ["Austria", "south Africa"] 
  #   }
  # }
  def filtered_index
    index
  end

  # GET /users/1
  # GET /users/1.xml
  def show
    unless is_api_request?
      @users_services = @user.services.paginate(:page => @page,
                                                :order => "created_at DESC")
                                                
      @users_paged_annotated_services_ids = @user.annotated_service_ids.paginate(:page => @page, :per_page => @per_page)
      @users_paged_annotated_services = BioCatalogue::Mapper.item_ids_to_model_objects(@users_paged_annotated_services_ids, "Service")
      
      @users_other_services_responsible = @user.other_services_responsible(@page, @per_page)
    end

    respond_to do |format|
      format.html # show.html.erb
      format.xml  # show.xml.builder
      format.json { render :json =>  @user.to_json }
    end
  end

  # GET /users/new
  # GET /users/new.xml
  def new
    @user = User.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @user }
    end
  end

  # GET /users/1/edit
  def edit
  end

  # POST /users
  # POST /users.xml
  def create
    @user = User.new(params[:user])

    respond_to do |format|
      if @user.save
        UserMailer.deliver_registration_notification(@user, base_host)
        #flash[:notice] = "Your account was successfully created.<p><b>Your account now needs to be activated.</b></p><p>You'll receive an email shortly to confirm the creation of your account and activate it.</p>"
        flash[:notice] = "<div class=\"flash_header\">An <b>email</b> has been sent to your address in order to complete your registration.</div><div class=\"flash_body\">If you don't receive this email in the next few minutes, please contact the <a href=\"/contact\">BioCatalogue Support</a>.</div>"
        format.html { redirect_to home_url }
        #format.xml  { render :xml => @user, :status => :created, :location => @user }
        format.xml { disable_action }
      else
        flash.now[:error] = 'Could not create new account.'
        format.html { render :action => "new" }
        format.xml  { render :xml => @user.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /users/1
  # PUT /users/1.xml
  def update
    respond_to do |format|
      if @user.update_attributes(params[:user])
        flash.now[:notice] = 'Successfully updated'
        format.html { render :action => "edit" }
        format.xml  { head :ok }
      else
        flash.now[:error] = 'Could not update. Please see errors below...'
        format.html { render :action => "edit" }
        format.xml  { render :xml => @user.errors, :status => :unprocessable_entity }
      end
    end
  end

  def activate_account
    unless params[:security_token] == nil
      user = User.find_by_security_token(params[:security_token], :conditions => "activated_at is null")
      if user
        if user.activate!
          session[:previous_url] = "/users/#{user.id}"
          flash[:notice] = "<div class=\"flash_header\">Account activated</div><div class=\"flash_body\">You can log into your account now.</div>"
          ActivityLog.create(@log_event_core_data.merge(:action => "activate", :activity_loggable => user)) if USE_EVENT_LOG
          return
        end
      end
    end
    flash[:error] = "<div class=\"flash_header\">Wrong activation code</div><div class=\"flash_body\">Please check the activation link or contact the <a href=\"/contact\">BioCatalogue Support</a>.</div>"
  end

  def forgot_password
    @user = User.new
  end

  def request_reset_password
    respond_to do |format|
      if @user = User.find_by_email(params[:user][:email], :conditions => "activated_at IS NOT NULL")
        @user.generate_security_token!
        UserMailer.deliver_reset_password(@user, base_host)
        format.html # request_reset_password.html.erb
      else
        flash[:error] = "No matching email address has been found or the account corresponding is not activated.<br />Please check the email address you entered or contact the <a href=\"/contact\">BioCatalogue Support</a>"
        format.html { redirect_to forgot_password_url }
      end
    end
  end

  def reset_password
    if params[:security_token] != nil && @user = User.find_by_security_token(params[:security_token], :conditions => "activated_at IS NOT NULL")
      if request.post?
        if @user.reset_password!(params[:user][:password], params[:user][:password_confirmation])
          flash[:notice] = "<div class=\"flash_header\">New password accepted.</div><div class=\"flash_body\">Please log in with your new password.</div>"
          session[:previous_url] = "/users/#{@user.id}"
          flash[:error] = nil
          ActivityLog.create(@log_event_core_data.merge(:action => "reset_password", :activity_loggable => @user)) if USE_EVENT_LOG
          redirect_to(login_url)
          return
        end
      end
    else
      flash[:error] = "No matching reset code has been found or the account corresponding is not activated.<br />Please check the reset link or contact the <a href=\"/contact\">BioCatalogue Support</a>"
      flash[:notice] = nil
    end
  end

  def change_password
    if request.post?
      if @user.reset_password!(params[:user][:password], params[:user][:password_confirmation])
        flash[:notice] = "<div class=\"flash_header\">New password accepted.</div>"
        session[:previous_url] = "/users/#{@user.id}"
        flash[:error] = nil
        ActivityLog.create(@log_event_core_data.merge(:action => "change_password", :activity_loggable => @user)) if USE_EVENT_LOG
        redirect_to(@user)
        return
      end
    end
  end
  
  def rpx_merge_setup
    if ENABLE_RPX
      if params[:token].blank? || (data = RPXNow.user_data(params[:token])).blank? || (rpx_user = User.find_by_identifier(data[:identifier])).nil?
        error("Unable to complete the merging of accounts", :status => 500)
        return
      else
        # This action is used for 2 different parts of the workflow:
        # 1) initial stage, where we get the user to log into the existing account.
        # 2) final stage, filling in any required fields/options and submitting the merge.
        
        if rpx_user.id == current_user.id
          flash[:notice] = "<b>Please sign in to the existing member account that you want to merge your new account into</b>"
          @rpx_login_required = true
        else
          @rpx_login_required = false
          @rpx_user = rpx_user
          @rpx_data = data
        end
        
        respond_to do |format|
          format.html
        end
      end
    else
      disable_action
    end
  end
  
  def rpx_merge
    if ENABLE_RPX
      if params[:token].blank? || (data = RPXNow.user_data(params[:token])).blank? || (rpx_user = User.find_by_identifier(data[:identifier])).nil? || !rpx_user.allow_merge?
        error("Unable to complete the merging of accounts", :status => 500)
        return
      else
        begin
          current_user.identifier = rpx_user.identifier
          current_user.save!
          rpx_user.destroy
          
          ActivityLog.create(@log_event_core_data.merge(:action => "rpx_merge", :activity_loggable => current_user, :data => { :deleted_account_id => rpx_user.id }))
          
          flash[:notice] = "Accounts successfully merged!"
          redirect_to(current_user)
        rescue Exception => ex
          logger.error "Failed to merge new RPX based account with an existing BioCatalogue account. Exception: #{ex.class.name} - #{ex.message}"
          logger.error ex.backtrace.join("\n")
          error("Sorry, something went wrong. Please contact us for further assistance.", :status => 500)
          return
        end
      end
    else
      disable_action
    end
  end
  
  def rpx_update
    if ENABLE_RPX
      respond_to do |format|
        begin
          if !params[:token].blank? && (data = RPXNow.user_data(params[:token]))
            user = User.find_by_identifier(data[:identifier])
            if user
              error_to_back_or_home("The external account you just verified has already been used in another account and cannot be added here. Please contact us if you would like these accounts merged.")
            else
              @user.identifier = data[:identifier]
              if @user.save
                flash[:notice] = 'You have successfully updated your external account and can now log in with it'
                format.html { redirect_to edit_user_url(@user) }
              else
                flash.now[:error] = 'Could not update your external account identifier. Please see errors below...'
                format.html { render :action => "edit" }
              end
            end
          else
            flash.now[:error] = "Unable to verify the external account. Please try again. If this problem persists we would appreciate it if you contacted us."
            format.html { render :action => "edit" }
          end
        rescue Exception => ex
          logger.error "Failed to update RPX identifier. Exception: #{ex.class.name} - #{ex.message}"
          logger.error ex.backtrace.join("\n")
          
          flash.now[:error] = "Sorry, something went wrong. Please try again. If this problem persists we would appreciate it if you contacted us."
          format.html { render :action => "edit" }
        end
      end
    else
      disable_action
    end
  end
  
  def annotations_by
    respond_to do |format|
      format.html { disable_action }
      format.xml { redirect_to(generate_include_filter_url(:sou, @user.id, "annotations", :xml)) }
      format.json { redirect_to(generate_include_filter_url(:sou, @user.id, "annotations", :json)) }
    end
  end
  
  def services
    respond_to do |format|
      format.html { disable_action }
      format.xml { redirect_to(generate_include_filter_url(:su, params[:id], "services", :xml)) }
      format.json { redirect_to(generate_include_filter_url(:su, params[:id], "services", :json)) }
    end
  end

  def filters
    respond_to do |format|
      format.html { disable_action }
      format.xml # filters.xml.builder
      format.json { render :json => BioCatalogue::Api::Json.filter_groups(@filter_groups).to_json }
    end
  end
    
  def saved_searches
    respond_to do |format|
      format.html { disable_action }
      format.xml # saved_searches.xml.builder
      format.json { render :json => @user.to_custom_json("saved_searches") }
    end
  end

private
  
  def parse_sort_params
    sort_by_allowed = [ "activated", "name" ]
    @sort_by = if params[:sort_by] && sort_by_allowed.include?(params[:sort_by].downcase)
      params[:sort_by].downcase
    else
      "activated"
    end
    
    sort_order_allowed = [ "asc", "desc" ]
    @sort_order = if params[:sort_order] && sort_order_allowed.include?(params[:sort_order].downcase)
      params[:sort_order].downcase
    else
      "desc"
    end
  end
  
  def find_users
    
    # Sorting
    
    order = 'users.activated_at DESC'
    order_field = nil
    order_direction = nil
    
    case @sort_by
      when 'activated'
        order_field = "activated_at"
      when 'name'
        order_field = "display_name"
    end
    
    case @sort_order
      when 'asc'
        order_direction = 'ASC'
      when 'desc'
        order_direction = "DESC"
    end
    
    unless order_field.blank? or order_direction.nil?
      order = "users.#{order_field} #{order_direction}"
    end
    
    conditions, joins = BioCatalogue::Filtering::Users.generate_conditions_and_joins_from_filters(@current_filters, params[:q])
    conditions = User.merge_conditions(conditions, "activated_at IS NOT NULL")

    if self.request.format == :bljson
      finder_options = {
        :select => "users.id, users.display_name",
        :order => order,
        :conditions => conditions,
        :joins => joins
      }
      
      @users = ActiveRecord::Base.connection.select_all(User.send(:construct_finder_sql, finder_options))
    else
      @users = User.paginate(:page => @page,
                             :per_page => @per_page,
                             :order => order,
                             :conditions => conditions,
                             :joins => joins)
  
    end
  end
  
  def find_user
    @user = User.find(params[:id], :conditions => "activated_at IS NOT NULL")
  end

  def check_user_rights
    find_user if !defined?(@user) or @user.nil?
    unless mine?(@user)     
      respond_to do |format|
        flash[:error] = "You don't have the rights to perform this action."
        format.html { redirect_to :users }
        format.xml  { redirect_to :users => @user.errors, :status => :unprocessable_entity }
        format.json  { error_to_back_or_home("You are not allowed to perform this action") }
      end
    end
  end
  
  def initialise_updated_user
    # Initialise a dummy user object for use in forms,
    # so that it remembers any data in between submission failures.
    @updated_user = User.new(params[:user])
    @updated_user.password = nil
    @updated_user.password_confirmation = nil
  end

end
