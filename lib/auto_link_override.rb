# BioCatalogue: lib/auto_link_override.rb

# This override is done as a fix for ampersands in URIs which are contained
# within annotations (example_endpoints, descriptions, documentation_urls, etc),
# but addresses other auto_link parsing problems (e.g. URIs with other characters
# in the query part).

# This fix works by overriding Rails's AUTO_LINK_RE regexp constant, which takes 
# a very generic approach to handling URIs.  The regexp below is more intricate
# and takes into account most of the URI form factors.  Rails's auto_link_urls 
# function is also overridden to make use of this method.

# From: http://railsforum.com/viewtopic.php?id=14293

ActionView::Helpers::TextHelper::AUTO_LINK_RE = %r{
  (
    <a\s.*?>.*??|               # Opening <a> tag.. and any other text including html tags which might be before a url
    [^\w]|                      # or, first char before url
    ^                           # or, start of line
  )
  (
    (?:https?://)?              # optional protocol
    (?:[-\w]+\.)+               # subdomain/domain parts
    (?:com|net|org|[a-z][a-z]|edu|gov|biz|int|mil|info|name|museum|coop|aero) # TLD
    (?::\d+)?                   # Optional port
    (?:/(?:(?:[~\w\+@%=-]|(?:[,.;:][^\s$]))+)?)*     # Path
    (?:\?[\w\+@%&=.;-]+)?       # Query String ?foo=bar
    (?:\#[\w\-]*)?              # Anchor
  )
  (
    (?:[^\w]|$)                 # Trailing Character
  )
}xi

ActionView::Helpers::TextHelper.module_eval do
  def auto_link_urls(text, href_options = {})
    extra_options = tag_options(href_options.stringify_keys) || ""
    text.gsub(ActionView::Helpers::TextHelper::AUTO_LINK_RE) do
      all, leading, url, trailing = $&, $1, $2, $3
      if leading =~ /<a\s/i # don't replace URL's that are already linked
        all
      else
        text = block_given? ? yield(url) : url
        url = 'http://' + url unless url =~ /^https?:\/\//
        %(#{leading}<a href="#{url}"#{extra_options}>#{text}</a>#{trailing})
      end
    end
  end
end
