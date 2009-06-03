class FavouritesController < ApplicationController
  
  before_filter :login_required, :only => [ :new, :create, :edit, :update, :destroy ]
  
  before_filter :find_favourite, :only => [ :show, :edit, :update, :destroy ] 
  before_filter :find_favouritable, :except => [ :show, :edit, :update, :destroy ]
  before_filter :authorise_action, :only =>  [ :edit, :update, :destroy ]
  
  # GET /favourites
  # GET /favourites.xml
  def index
    @favourites = Favourite.find(:all)

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @favourites }
    end
  end

  # GET /favourites/1
  # GET /favourites/1.xml
  def show
    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @favourite }
    end
  end

  # GET /favourites/new
  # GET /favourites/new.xml
  def new
    @favourite = Favourite.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @favourite }
    end
  end

  # POST /favourites
  # POST /favourites.xml
  def create
    @favourite = Favourite.new(params[:favourite])
    @favourite.user = current_user

    respond_to do |format|
      if @favourite.save
        flash[:notice] = 'Item successfully added to your favourites'
        format.html { redirect_to :back }
        format.xml  { render :xml => @favourite, :status => :created, :location => @favourite }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @favourite.errors, :status => :unprocessable_entity }
      end
    end
  end
  
  # GET /favourites/1/edit
  def edit
  end

  # PUT /favourites/1
  # PUT /favourites/1.xml
  def update
    respond_to do |format|
      if @favourite.update_attributes(params[:favourite])
        flash[:notice] = 'Favourite was successfully updated'
        format.html { redirect_to :back }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @favourite.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /favourites/1
  # DELETE /favourites/1.xml
  def destroy
    @favourite.destroy

    respond_to do |format|
      flash[:notice] = 'Item successfully removed from your favourites'
      format.html { redirect_to :back }
      format.xml  { head :ok }
    end
  end
  
  protected
  
  def find_favourite
    @favourite = Favourite.find(params[:id])
  end
  
  def find_favouritable
    @favouritable = nil
    
    if params[:favourite]
      @favouritable = Favourite.find_favouritable(params[:favourite][:favouritable_type], params[:favourite][:favouritable_id])
    end
    
    # If still nil try again with alternative params
    if @favouritable.nil?
      @favouritable = Favourite.find_favouritable(params[:favouritable_type], params[:favouritable_id])
    end
  end
  
  def authorise_action
    if !logged_in? or (@favourite.user_id != current_user.id)
      # TODO: return either a 401 or 403 depending on authentication
      respond_to do |format|
        flash[:error] = 'You are not allowed to perform this action.'
        format.html { redirect_to :back }
        format.xml  { head :forbidden }
      end
      return false
    end
    return true
  end
  
end
