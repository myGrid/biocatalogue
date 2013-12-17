# BioCatalogue: app/helpers/users_helper.rb
#
# Copyright (c) 2008-2009, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details.

module UsersHelper
  
  def rpx_accounts_provider_logos
    a = image_tag("openidW.png", :alt => "OpenID", :class => "account_provider_logo") +
    image_tag("myopenidW.png", :alt => "myOpenID", :class => "account_provider_logo") +
    image_tag("googleW.png", :alt => "Google", :class => "account_provider_logo") +
    image_tag("yahooW.png", :alt => "Yahoo!", :class => "account_provider_logo") +
    image_tag("facebookW.png", :alt => "Facebook", :class => "account_provider_logo")
    return a.html_safe
  end
  
  def rpx_accounts_provider_logos_with_link
        RPXNow.popup_code(rpx_accounts_provider_logos,
                      RPX_REALM,
                      session_rpx_token_url).html_safe
  end
  
  def list_of_rpx_accounts
    "<strong>OpenID</strong>, 
    <strong>Google</strong>, 
    <strong>Facebook</strong>, 
    <strong>Twitter</strong>, 
    <strong>Yahoo!</strong> or 
    <strong>Verisign</strong>".html_safe
  end
  
  def external_account_field_help_icon
    help_icon_with_tooltip(content_tag(:p, rpx_accounts_provider_logos, :class => "center") + 
      content_tag(:p, "You can link one external account to your #{SITE_NAME} account to make it
        easier to sign in. We currently support the following providers: ".html_safe +
        list_of_rpx_accounts))
  end
  
  def account_sign_in_options_info
    if ENABLE_RPX
      "To sign in to #{SITE_NAME} you can use either a <strong>#{SITE_NAME} specific account</strong> (i.e.: an email address and password registered here)
      or an external account (i.e.: an existing #{list_of_rpx_accounts} account that you link to here).".html_safe
    else
      "To sign in to #{SITE_NAME} use the email address and password you registered with".html_safe
    end
  end

  def generate_include_deactivated_url(resource, should_include_deactivated)
    params_dup = BioCatalogue::Util.duplicate_params(params)
    params_dup[:include_deactivated] = should_include_deactivated.to_s

    # Reset page param
    params_dup.delete(:page)

    return eval("#{resource}_url(params_dup)")
  end
end
