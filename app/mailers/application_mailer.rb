# BioCatalogue: app/views/mailers/application_mailer.rb
#
# Copyright (c) 2009, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

class ApplicationMailer < ActionMailer::Base
  self.template_root = File.join(Rails.root, 'app', 'mailers', 'views')
end