# BioCatalogue: app/models/user_mailer.rb
#
# Copyright (c) 2008-2010, University of Manchester, The European Bioinformatics
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

class UserMailer < ActionMailer::Base
  default :from => SENDER_EMAIL_ADDRESS

  def registration_notification(user, base_url)
    @user = user
    @base_url = base_url

    mail(:to => user.email, :subject => "[#{SITE_NAME}] Please activate your new account")
  end

  def reset_password(user, base_url)
    @user = user
    @base_url = base_url

    mail(:to => user.email, :subject => "[#{SITE_NAME}] Resetting your password - Step 2")
  end
  
  def testscript_status_notification(user, base_url, testscript)
    @user = user
    @base_url = base_url
    @test_script = testscript

    mail(:to => user.email, :subject => "[#{SITE_NAME}] Your test script status changed")
  end
  
  def responsibility_request_notification(owner, base_url, service, user)
    @user = user # user is the one making the request
    @owner = owner
    @base_url = base_url
    @service = service

    mail(:to => owner.email, :subject => "[#{SITE_NAME}] Service Reponsibility Request")
  end
  
  def responsibility_request_cancellation(owner, base_url, service, user, req)
    @user = user # user is the one cancelling the request
    @owner = owner
    @base_url = base_url
    @service = service
    @req = req

    mail(:to => owner.email, :subject => "[#{SITE_NAME}] Service Reponsibility Request Cancellation")
  end
  
  def responsibility_request_approval(owner, base_url, service, user, req )
    @user = user # user is the one approving the request
    @owner = owner
    @base_url = base_url
    @service = service
    @req = req

    mail(:to => owner.email, :subject => "[#{SITE_NAME}] Service Responsibility Approved")
  end
  
  def responsibility_request_refusal(owner, base_url, user, req)
    @user = user # user is the one turning down the request
    @owner = owner
    @base_url = base_url
    @service = service
    @req = req

    mail(:to => owner.email, :subject => "[#{SITE_NAME}] Service Reponsibility Request Turned Down")
  end
  
  def claimant_responsibility_notification(user, base_url, service)
    @user = user
    @base_url = base_url
    @service = service

    mail(:to => user.email, :subject => "[#{SITE_NAME}] Your request to take responsibility for a Service")
  end

  def orphaned_provider_notification(user_emails, base_url, provider)
    @base_url = base_url
    @provider = provider

    mail(:to => user_emails, :subject => "[#{SITE_NAME}] The system has a Service Provider with no services")
  end
  
  def service_test_disable_notification(user, service_test, to_emails, base_url)
    @user = user
    @base_url = base_url
    @service_test = service_test

    mail(:to => to_emails, :subject => "[#{SITE_NAME}] A service test has been disabled!")
  end
  
end
