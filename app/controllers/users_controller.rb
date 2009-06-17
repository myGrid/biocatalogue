# BioCatalogue: app/controllers/users_controller.rb
#
# Copyright (c) 2008, University of Manchester, The European Bioinformatics
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details.

class UsersController < ApplicationController

  before_filter :disable_action, :only => [ :destroy ]

  before_filter :login_required, :except => [:index, :new, :create, :show, :activate_account, :forgot_password, :request_reset_password, :reset_password]
  before_filter :check_user_rights, :only => [:edit, :update, :destroy, :change_password]

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
    @user = User.find(params[:id])
    @users_services = @user.services.paginate(:page => params[:page],
                                              :order => "created_at DESC")

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
    @user = User.find(params[:id])
  end

  # POST /users
  # POST /users.xml
  def create
    @user = User.new(params[:user])

    respond_to do |format|
      if @user.save
        UserMailer.deliver_registration_notification(@user, base_host)
        #flash[:notice] = "Your account was successfully created.<p><b>Your account now needs to be activated.</b></p><p>You'll receive an email shortly to confirm the creation of your account and activate it.</p>"
        flash[:notice] = "<div class=\"flash_header\">An <b>email</b> as been sent to your address<br />in order to complete your registration.</div><div class=\"flash_body\">If you haven't received this email in the next few minutes,<br />please contact the <a href=\"/contact\">BioCatalogue Support</a>.</div>"
        format.html { redirect_to(@user) }
        format.xml  { render :xml => @user, :status => :created, :location => @user }
      else
        flash[:error] = 'Could not create new account.'
        format.html { render :action => "new" }
        format.xml  { render :xml => @user.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /users/1
  # PUT /users/1.xml
  def update
    @user = User.find(params[:id])

    respond_to do |format|
      if @user.update_attributes(params[:user])
        flash[:notice] = 'Account was successfully updated.'
        format.html { redirect_to(@user) }
        format.xml  { head :ok }
      else
        flash[:error] = 'Could not modify the account.'
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
          session[:original_uri] = "/users/#{user.id}"
          flash[:notice] = "<div class=\"flash_header\">Account activated.</div><div class=\"flash_body\">You can log into your account now.</div>"
          ActivityLog.create(:action => "activate", :activity_loggable => user)
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
    if @user = User.find_by_email(params[:user][:email])
      @user.generate_security_token!
      UserMailer.deliver_reset_password(@user, base_host)
      return
    end
    flash[:error] = "<div class=\"flash_header\">Could not find the user.</div><div class=\"flash_body\">No matching email address has been found or the account corresponding is not activated.<br />Please check the email address you entered or contact the <a href=\"/contact\">BioCatalogue Support</a>.</div>"
    flash[:notice] = nil
  end

  def reset_password
    if params[:security_token] != nil && @user = User.find_by_security_token(params[:security_token], :conditions => "activated_at is not null")
      if request.post?
        if @user.reset_password!(params[:user][:password], params[:user][:password_confirmation])
          flash[:notice] = "<div class=\"flash_header\">New password accepted.</div><div class=\"flash_body\">Please log in with your new password.</div>"
          session[:original_uri] = "/users/#{@user.id}"
          flash[:error] = nil
          ActivityLog.create(:action => "reset_password", :activity_loggable => @user)
          redirect_to(new_session_url)
          return
        end
      end
    else
      flash[:error] = "<div class=\"flash_header\">Could not find the user.</div><div class=\"flash_body\">No matching reset code has been found or the account corresponding is not activated.<br />Please check the reset link or contact the <a href=\"/contact\">BioCatalogue Support</a>.</div>"
      flash[:notice] = nil
    end
  end

  def change_password
    @user = User.find(params[:id])
    if request.post?
      if @user.reset_password!(params[:user][:password], params[:user][:password_confirmation])
        flash[:notice] = "<div class=\"flash_header\">New password accepted.</div>"
        session[:original_uri] = "/users/#{@user.id}"
        flash[:error] = nil
        ActivityLog.create(:action => "change_password", :activity_loggable => @user)
        redirect_to(@user)
        return
      end
    end
  end

  private

  def check_user_rights
    user = User.find(params[:id])
    unless mine?(user)
      respond_to do |format|
        flash[:error] = "You don't have the rights to perform this action."
        format.html { redirect_to :users }
        format.xml  { redirect_to :users => @user.errors, :status => :unprocessable_entity }
      end
    end
  end

end
