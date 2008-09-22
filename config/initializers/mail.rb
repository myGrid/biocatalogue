ActionMailer::Base.raise_delivery_errors = true
ActionMailer::Base.perform_deliveries = true
ActionMailer::Base.default_charset = 'utf-8'
ActionMailer::Base.delivery_method = :smtp

ActionMailer::Base.smtp_settings = {
  :address          => 'smtp.ebi.ac.uk',
  :port             => 25,
  :domain           => 'ebi.ac.uk'
}
