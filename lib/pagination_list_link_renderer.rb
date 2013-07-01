# Overriding the way will_paginate returns the list of links to pages with
# links to previous, next, etc.
# As per http://thewebfellas.com/blog/2010/8/22/revisited-roll-your-own-pagination-links-with-will_paginate-and-rails-3
#
# will_paginate returns:
# <div class="pagination">
#  <a class="previous_page disabled" >← Previous</span>
#  <em class="current">1</em>
#  <a rel="next" href="/users?page=2">2</a>
#  <a href="/users?page=3">3</a>
#  <a href="/users?page=4">4</a>
#  <a class="next_page" rel="next" href="/users?page=2">Next →</a>
#</div>

# We want (<span> instead of <em> for the current page and nice arrows for previous/next buttons):
# <div class="pagination">
#  <a class="previous_page disabled">« Previous</span>
#  <span class="current">1</span>
#  <a rel="next" href="/users?page=2">2</a>
#  <a href="/users?page=3">3</a>
#  <a href="/users?page=4">4</a>
#  <a class="next_page" rel="next" href="/users?page=2">Next »</a>
#</div>
class PaginationListLinkRenderer < WillPaginate::ActionView::LinkRenderer

  protected

  def page_number(page)
    unless page == current_page
      link(page, page, :rel => rel_value(page))
    else
      tag(:span, page, :class => "current")
    end
  end

end