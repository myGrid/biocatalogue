# BioCatalogue: app/controllers/soaplab_servers_controller.rb
#
# Copyright (c) 2008, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details.

class SoaplabServersController < ApplicationController
  # GET /soaplab_servers
  # GET /soaplab_servers.xml
  def index
    @soaplab_servers = SoaplabServer.find(:all, :order => 'id DESC')

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @soaplab_servers }
    end
  end

  # GET /soaplab_servers/1
  # GET /soaplab_servers/1.xml
  def show
    @soaplab_server = SoaplabServer.find(params[:id])
    @new_existing_urls = @soaplab_server.new_existing_urls(@soaplab_server.wsdl_urls)
    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @soaplab_server }
    end
  end

  # GET /soaplab_servers/new
  # GET /soaplab_servers/new.xml
  def new
    @soaplab_server = SoaplabServer.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @soaplab_server }
    end
  end

  # GET /soaplab_servers/1/edit
  def edit
    @soaplab_server = SoaplabServer.find(params[:id])
  end

  # POST /soaplab_servers
  # POST /soaplab_servers.xml
  def create
    @soaplab_server = SoaplabServer.new(params[:soaplab_server])

    respond_to do |format|
      if @soaplab_server.save
        @new_services, @existing_services, @error_urls = @soaplab_server.save_services(current_user)
        flash[:notice] = 'SoaplabServer was successfully created.'
        format.html { redirect_to(@soaplab_server) }
        format.xml  { render :xml => @soaplab_server, :status => :created, :location => @soaplab_server }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @soaplab_server.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /soaplab_servers/1
  # PUT /soaplab_servers/1.xml
  def update
    @soaplab_server = SoaplabServer.find(params[:id])

    respond_to do |format|
      if @soaplab_server.update_attributes(params[:soaplab_server])
        flash[:notice] = 'SoaplabServer was successfully updated.'
        format.html { redirect_to(@soaplab_server) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @soaplab_server.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /soaplab_servers/1
  # DELETE /soaplab_servers/1.xml
  def destroy
    @soaplab_server = SoaplabServer.find(params[:id])
    @soaplab_server.destroy

    respond_to do |format|
      format.html { redirect_to(soaplab_servers_url) }
      format.xml  { head :ok }
    end
  end
end
