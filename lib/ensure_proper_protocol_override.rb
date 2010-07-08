# BioCatalogue: lib/ensure_proper_protocol_override.rb

# This override is done to bypass https redirection in development mode.

# From: http://www.hostingrails.com/SSL-Redirecting-not-working

module SslRequirement
  private

  def ensure_proper_protocol
    case RAILS_ENV
      when 'test', 'development'
        return true
      when 'production'
        return true if ssl_allowed?
        
        if ssl_required? && !request.ssl?
          redirect_to "https://" + request.host + request.request_uri
          flash.keep
          return false
        elsif request.ssl? && !ssl_required?
          redirect_to "http://" + request.host + request.request_uri
          flash.keep
          return false
        end
    end
  end
end
