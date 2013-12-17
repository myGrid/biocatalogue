# Replacement for old Rails 2 style metal in app/metal/alive.rb
class AliveController < ActionController::Metal

  def index
    self.content_type = 'text/html'
    self.status = '200'
    self.response_body = 'I am Alive!'
  end

end
