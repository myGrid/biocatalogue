# BioCatalogue: app/helpers/users_helper.rb
#
# Copyright (c) 2008-2009, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details.

module UsersHelper
  
  def rpx_accounts_provider_logos
    image_tag("openidW.png", :alt => "OpenID", :class => "account_provider_logo") +
    image_tag("myopenidW.png", :alt => "myOpenID", :class => "account_provider_logo") +
    image_tag("googleW.png", :alt => "Google", :class => "account_provider_logo") +
    image_tag("yahooW.png", :alt => "Yahoo!", :class => "account_provider_logo") +
    image_tag("facebookW.png", :alt => "Facebook", :class => "account_provider_logo")
  end
  
  def rpx_accounts_provider_logos_with_link
    RPXNow.popup_code(rpx_accounts_provider_logos, 
                      RPX_REALM, 
                      rpx_token_sessions_url)
  end
  
  def list_of_rpx_accounts
    "<strong>OpenID</strong>, 
    <strong>Google</strong>, 
    <strong>Facebook</strong>, 
    <strong>Twitter</strong>, 
    <strong>Yahoo!</strong> or 
    <strong>Verisign</strong>"
  end
  
  def external_account_field_help_icon
    help_icon_with_tooltip(content_tag(:p, rpx_accounts_provider_logos, :class => "center") + 
      content_tag(:p, "You can link one external account to your BioCatalogue account to make it 
        easier to sign in. We currently support the following providers: " +
        list_of_rpx_accounts))
  end
  
  def account_sign_in_options_info
    if ENABLE_RPX
      "To sign in to the BioCatalogue you can use either a <strong>BioCatalogue specific account</strong> (i.e.: an email address and password registered here) 
      or an external account (i.e.: an existing #{list_of_rpx_accounts} account that you link to here)."
    else
      "To sign in to the BioCatalogue use the email address and password you registered with"
    end
  end
   
end
