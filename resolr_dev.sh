#!/bin/bash

export RAILS_ENV=development

echo '(Service.rebuild_solr_index) if ENABLE_SEARCH' | ruby script/console
echo '(User.rebuild_solr_index) if ENABLE_SEARCH' | ruby script/console
echo '(ServiceProvider.rebuild_solr_index) if ENABLE_SEARCH' | ruby script/console

