# BioCatalogue: app/models/user_mailer.rb
#
# Copyright (c) 2008, University of Manchester, The European Bioinformatics
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

class UserMailer < ActionMailer::Base
  def registration_notification(user, base_url)
    content_type "text/html"
    recipients  user.email
    from        "biocatalogue-support@rubyforge.org"
    subject     "Please activate your new account"
    body        :user => user,
                :base_url => base_url
  end

  def reset_password(user, base_url)
    content_type "text/html"
    recipients  user.email
    from        "biocatalogue-support@rubyforge.org"
    subject     "Resetting your password - Step 2"
    body        :user => user,
                :base_url => base_url
  end

end
