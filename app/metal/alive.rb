# Allow the metal piece to run in isolation
#require(File.dirname(__FILE__) + "/../../config/environment") unless defined?(Rails)

class Alive < Rails::Rack::Metal
  def self.call(env)
    if env["PATH_INFO"] =~ /^\/alive/
      [200, {"Content-Type" => "text/html"}, ["I am Alive!"]]
    else
      [404, {"Content-Type" => "text/html"}, ["Not Found"]]
    end
  end
end
