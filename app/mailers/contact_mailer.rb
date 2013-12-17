# BioCatalogue: app/views/mailers/contact_mailer.rb
#
# Copyright (c) 2009, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

class ContactMailer < UserMailer
  default :from => SENDER_EMAIL_ADDRESS

  def feedback(name, msg_subject, content)
    @name = name
    @msg_subject = msg_subject
    @content = content

    mail(:to => FEEDBACK_EMAIL_ADDRESS, :subject => "#{SITE_NAME} feedback from #{name}")
  end
end