#!/bin/bash

export RAILS_ENV=development

echo '(Service.find_all.map do |s| s.solr_save end) if ENABLE_SEARCH' | ruby script/console

