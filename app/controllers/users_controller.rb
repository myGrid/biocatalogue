class UsersController < ApplicationController

  before_filter :login_required, :except => [:index, :new, :create, :show, :activate_account]
  before_filter :check_user_rights, :only => [:edit, :update, :destroy]
  
  # GET /users
  # GET /users.xml
  def index
    @users = User.find(:all)

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @users }
    end
  end

  # GET /users/1
  # GET /users/1.xml
  def show
    @user = User.find(params[:id])

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
        UserMailer.deliver_registration_notification(@user)
        flash[:notice] = 'User was successfully created.'
        format.html { redirect_to(@user) }
        format.xml  { render :xml => @user, :status => :created, :location => @user }
      else
        flash[:error] = 'Could not create new user.'
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
        flash[:notice] = 'User was successfully updated.'
        format.html { redirect_to(@user) }
        format.xml  { head :ok }
      else
        flash[:error] = 'Could not mofify user.'
        format.html { render :action => "edit" }
        format.xml  { render :xml => @user.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /users/1
  # DELETE /users/1.xml
  def destroy
    @user = User.find(params[:id])
    @user.destroy
    session.delete
    respond_to do |format|
      format.html { redirect_to(users_url) }
      format.xml  { head :ok }
    end
  end
  
  def activate_account
    unless params[:security_token] == nil
      # TODO: use User.find_by_security_token for performance reasons!
      users = User.find(:all)
      users.each do |user|
        token = user.security_token
        if token == params[:security_token]
            # TODO: refactor this into the User model, ie: into a user.activate! method instead of doing it in the controller.
            # TODO: DON'T use the update_attribute method as it bypasses AR validations.
            if user.update_attribute(:activated_at, Time.now)
              user.update_attribute(:security_token, nil)
              flash[:notice] = "Account activated. You can log into your account now."
              ActivityLog.create(:action => "activate", :activity_loggable => user)
              return
            end
        end
      end
    end
    flash[:error] = "Wrong activation code. Please contact the Administrator."
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
