# BioCatalogue: app/views/mailers/contact_mailer.rb
#
# Copyright (c) 2009, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

class ContactMailer < ApplicationMailer
  def feedback(name, subject, content)
    recipients FEEDBACK_EMAIL_ADDRESS
    from SENDER_EMAIL_ADDRESS
    subject "BioCatalogue feedback from #{name}"
    
    body :name => name, 
         :subject => subject, 
         :content => content
  end
end