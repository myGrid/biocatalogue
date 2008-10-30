#!/bin/bash

export RAILS_ENV=production

echo '(Service.find_all.map do |s| s.solr_save end) if ENABLE_SEARCH' | ruby script/console

