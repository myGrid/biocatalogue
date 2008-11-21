# BioCatalogue: app/models/user_mailer.rb
#
# Copyright (c) 2008, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

class UserMailer < ActionMailer::Base
  def registration_notification(user)
    content_type "text/html"
    recipients  user.email
    from        "biocatalogue-support@rubyforge.org"
    subject     "Please activate your new account"
    body        :user => user
  end

end
