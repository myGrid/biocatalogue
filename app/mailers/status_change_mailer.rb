# BioCatalogue: app/views/mailers/status_change_mailer.rb
#
# Copyright (c) 2010, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

class StatusChangeMailer < UserMailer
  default :from => SENDER_EMAIL_ADDRESS

  def text_to_email(email_subject, content, recipient)
    @content = content

    mail(:to => recipient, :subject => email_subject)
  end
end
