# BioCatalogue: app/controllers/users_controller.rb
#
# Copyright (c) 2008, University of Manchester, The European Bioinformatics
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details.

class UsersController < ApplicationController

  before_filter :disable_action, :only => [ :destroy ]

  before_filter :login_required, :except => [ :index, :new, :create, :show, :activate_account, :forgot_password, :request_reset_password, :reset_password, :rpx_merge_setup ]
  before_filter :check_user_rights, :only => [ :edit, :update, :destroy, :change_password ]
  
  before_filter :initialise_updated_user, :only => [ :edit, :update ]
  
  skip_before_filter :verify_authenticity_token, :only => [ :rpx_update ]
  
  before_filter :find_user, :only => [ :show, :edit, :update, :change_password, :rpx_update ]
  
  before_filter :add_use_tab_cookie_to_session, :only => [ :show ]

  # GET /users
  # GET /users.xml
  def index
    @users = User.paginate(:page => params[:page],
                           :conditions => "activated_at IS NOT NULL",
                           :order => 'activated_at DESC')

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @users }
    end
  end

  # GET /users/1
  # GET /users/1.xml
  def show
    @users_services = @user.services.paginate(:page => params[:page],
                                              :order => "created_at DESC")
                                              
    users_annotated_service_ids = @user.annotated_service_ids 
    @users_paged_annotated_services_ids = users_annotated_service_ids.paginate(:page => params[:page], :per_page => PAGE_ITEMS_SIZE)
    @users_paged_annotated_services = BioCatalogue::Mapper.item_ids_to_model_objects(@users_paged_annotated_services_ids, "Service")

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @user }
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
        flash[:notice] = "<div class=\"flash_header\">An <b>email</b> has been sent to your address in order to complete your registration.</div><div class=\"flash_body\">If you haven't received this email in the next few minutes, please contact the <a href=\"/contact\">BioCatalogue Support</a>.</div>"
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

  # DELETE /users/1
  # DELETE /users/1.xml
#  def destroy
#    @user = User.find(params[:id])
#    @user.destroy
#    session.delete
#    respond_to do |format|
#      format.html { redirect_to(users_url) }
#      format.xml  { head :ok }
#    end
#  end

  def activate_account
    unless params[:security_token] == nil
      user = User.find_by_security_token(params[:security_token], :conditions => "activated_at is null")
      if user
        if user.activate!
          session[:previous_url] = "/users/#{user.id}"
          flash[:notice] = "<div class=\"flash_header\">Account activated.</div><div class=\"flash_body\">You can log into your account now.</div>"
          ActivityLog.create(@log_event_core_data.merge(:action => "activate", :activity_loggable => user)) if USE_EVENT_LOG
          return
        end
      end
    end
    flash[:error] = "<div class=\"flash_header\">Wrong activation code.</div><div class=\"flash_body\">Please check the activation link or contact the <a href=\"/contact\">BioCatalogue Support</a>.</div>"
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
        error_to_home("Unable to complete the merging of accounts")
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
        error_to_home("Unable to complete the merging of accounts")
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
          error_to_home("Sorry, something went wrong. Please contact us for further assistance.")
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
  
  private
  
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
