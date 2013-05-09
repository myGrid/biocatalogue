ENV["RAILS_ENV"] = "test"
require File.expand_path(File.dirname(__FILE__) + "/../config/environment")
#require File.expand_path(File.dirname(__FILE__) + "/factories/user.rb")
require 'test_help'

class ActiveSupport::TestCase
  # Transactional fixtures accelerate your tests by wrapping each test method
  # in a transaction that's rolled back on completion.  This ensures that the
  # test database remains unchanged so your fixtures don't have to be reloaded
  # between every test method.  Fewer database queries means faster tests.
  #
  # Read Mike Clark's excellent walkthrough at
  #   http://clarkware.com/cgi/blosxom/2005/10/24#Rails10FastTesting
  #
  # Every Active Record database supports transactions except MyISAM tables
  # in MySQL.  Turn off transactional fixtures in this case; however, if you
  # don't care one way or the other, switching from MyISAM to InnoDB tables
  # is recommended.
  #
  # The only drawback to using transactional fixtures is when you actually 
  # need to test transactions.  Since your test is bracketed by a transaction,
  # any transactions started in your code will be automatically rolled back.
  self.use_transactional_fixtures = true

  # Instantiated fixtures are slow, but give you @david where otherwise you
  # would need people(:david).  If you don't want to migrate your existing
  # test cases which use the @david style and don't mind the speed hit (each
  # instantiated fixtures translates to a database query per test method),
  # then set this back to true.
  self.use_instantiated_fixtures  = false

  # Setup all fixtures in test/fixtures/*.(yml|csv) for all tests in alphabetical order.
  #
  # Note: You'll currently still have to declare fixtures explicitly in integration tests
  # -- they do not yet inherit this setting
  fixtures :all

  
  # ========================================
  
  
  # This is a generic method to create and submit a rest method which can be used
  # within tests
  #
  # CONFIGURATION OPTIONS
  #
  # name: the name you would like the REST service to have
  #   default "my test REST service"
  # base_endpoint: specifies the base endpoint for the REST service
  #   default "http://www.my-service.com/api/v1/"
  # submitter: the user who is submitting the REST service.  When no user is
  #   specified, a new user is created
  # annotations: the annotations hash
  #   default: {}
  # endpoint: additional resource-method combos (endpoints) seperated by a new line
  #   character "\n"
  #   default ""
  def create_rest_service(*args)
    options = args.extract_options!
    options.reverse_merge!(:name => "my test REST service",
                           :base_endpoint => "http://www.my-service.com/api/v1/",
                           :submitter => Factory.create(:user),
                           :annotations => {:name => ""},
                           :endpoints => "")
    
    rest = RestService.new(:name => options[:name])
    rest.submit_service(options[:base_endpoint], options[:submitter], options[:annotations], options[:endpoints])
    
    rest.service(true)
    return rest
  end
  
  # ========================================
  
  # TODO: should this return a User object back?
  def do_login_for_functional_test(user=Factory.create(:user))
    session[:user_id] = user.id
  end
   
  # ========================================

  def login_and_return_first_method(endpoint="")
    user = Factory.create(:user)
    do_login_for_functional_test(user)
  
    @rest = create_rest_service(:submitter => user, :endpoints => endpoint)
    return @rest.rest_resources[0].rest_methods[0]
  end

end
