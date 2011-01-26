# BioCatalogue: app/views/mailers/status_change_mailer.rb
#
# Copyright (c) 2010, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

class MemberInfoMailer < ApplicationMailer
  def text_to_email(email_subject, content, recipient)
    recipients recipient
    from FEEDBACK_EMAIL_ADDRESS
    subject email_subject
    
    body :content => content
  end
end
