#!/bin/bash

export RAILS_ENV=development

echo '(Service.find(:all).map do |s| s.solr_save end) if ENABLE_SEARCH' | ruby script/console

