class UserMailer < ActionMailer::Base
  def registration_notification(user)
    content_type "text/html"
    recipients  user.email
    from        "tlaurent@ebi.ac.uk"
    subject     "Please activate your new account"
    body        :user => user
  end

end
