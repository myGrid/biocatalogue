#!/bin/bash

export RAILS_ENV=production

echo '(Service.find(:all).map do |s| s.solr_save end) if ENABLE_SEARCH' | ruby script/console
echo '(User.find(:all).map do |u| u.solr_save end) if ENABLE_SEARCH' | ruby script/console

