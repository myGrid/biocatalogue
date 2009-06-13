# Set up loggers to STDOUT if in script/console 
# (so now things like SQL queries etc are shown in the console instead of the development/production/etc logs).
if "irb" == $0
  ActiveRecord::Base.logger = Logger.new(STDOUT)
  ActionController::Base.logger = Logger.new(STDOUT)
end