#!/usr/bin/env ruby

# Send an email to members of the BioCatalogue that have consented to
# receiving notification.
#
# NOTE : Use with extreme caution!! People hate spam!!!
#
#
#    -e, --environment=name           Specifies the environment to run this script under (test|development|production).
#                                     Default: development
#
#    -h, --help                       Show this help message.
#
# Depedencies:
# - Rails (v2.3.2)

require 'optparse'
require 'benchmark'




class MemberInfoMailing
  
  attr_accessor :options
  
  def initialize(args)
    @options = {
      :environment => (ENV['RAILS_ENV'] || "production").dup,
    }
    
    args.options do |opts|
      opts.on("-e", "--environment=name", String,
              "Specifies the environment to run this script under (test|development|production).",
              "Default: development") { |v| @options[:environment] = v }
    
      opts.separator ""
    
      opts.on("-h", "--help", "Show this help message.") { puts opts; exit }
      
      opts.parse!
    end
  
    # Start the Rails app
    
    ENV["RAILS_ENV"] = @options[:environment]
    RAILS_ENV.replace(@options[:environment]) if defined?(RAILS_ENV)
    
    require File.join(File.dirname(__FILE__), '..', '..', 'config', 'environment')
    
    @subject = "My message subject"
    
    @message = " My message content..."
    
    
  end  
  
  def mail_members
    members = User.all
    members.each do |member|
      if member.respond_to?(:email) && member.email && member.receive_notifications && member.activated_at
        Delayed::Job.enqueue(BioCatalogue::Jobs::MemberInfoEmail.new(@subject, @message, member.email), :priority => 0, :run_at => 5.seconds.from_now)
      end
    end
  end
  
end

MemberInfoMailing.new(ARGV.clone).mail_members

