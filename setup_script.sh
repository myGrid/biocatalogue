#!/bin/bash

APP_DIR=`pwd`

GIT_REMOTE=origin
LOCAL_BRANCH=rails3
REMOTE_BRANCH=${GIT_REMOTE}/${LOCAL_BRANCH}

branch_name="$(git symbolic-ref HEAD 2>/dev/null)"
branch_name=${branch_name##refs/heads/}

git show-branch $LOCAL_BRANCH 2> /dev/null
if [ $? != 0 ]  # if $LOCAL_BRANCH branch does not exists
then
    echo "Creating new local branch $LOCAL_BRANCH to track $REMOTE_BRANCH..."
    git branch --track $LOCAL_BRANCH $REMOTE_BRANCH
fi

echo "Switching to branch $LOCAL_BRANCH"
git checkout $LOCAL_BRANCH

echo "Running bundle install..."
bundle install

[ ! -f ${APP_DIR}/config/database.yml ] && cp ${APP_DIR}/config/database.yml.pre ${APP_DIR}/config/database.yml && echo "Created ${APP_DIR}/config/database.yml"
[ ! -f ${APP_DIR}/config/memcache.yml ] && cp ${APP_DIR}/config/memcache.yml.pre ${APP_DIR}/config/memcache.yml  && echo "Created ${APP_DIR}/config/memcache.yml"
[ ! -f ${APP_DIR}/config/sunspot.yml ] && cp ${APP_DIR}/config/sunspot.yml.pre ${APP_DIR}/config/sunspot.yml  && echo "Created ${APP_DIR}/config/sunspot.yml"
[ ! -f ${APP_DIR}/config/initializers/biocat_local.rb ] && cp ${APP_DIR}/config/initializers/biocat_local.rb.pre ${APP_DIR}/config/initializers/biocat_local.rb && echo "Created ${APP_DIR}/config/initializers/biocat_local.rb"
[ ! -f ${APP_DIR}/config/initializers/mail.rb ] && cp ${APP_DIR}/config/initializers/mail.rb.pre ${APP_DIR}/config/initializers/mail.rb && echo "Created ${APP_DIR}/config/initializers/mail.rb"
[ ! -f ${APP_DIR}/config/initializers/secret_token.rb ] && cp ${APP_DIR}/config/initializers/secret_token.rb.pre ${APP_DIR}/config/initializers/secret_token.rb && echo "Created ${APP_DIR}/config/initializers/secret_token.rb"
[ ! -f ${APP_DIR}/data/service_categories.yml ] && cp ${APP_DIR}/data/service_categories.yml.pre ${APP_DIR}/data/service_categories.yml && echo "Created ${APP_DIR}/data/service_categories.yml"
[ ! -f ${APP_DIR}/app/assets/stylesheets/colours/override.css.scss ] && cp ${APP_DIR}/app/assets/stylesheets/colours/override.css.scss.pre ${APP_DIR}/app/assets/stylesheets/colours/override.css.scss && echo "Created ${APP_DIR}/app/assets/stylesheets/colours/override.css.scss"
echo
echo "Please remember to configure the following to suit your environment:" 
echo "config/database.yml"
echo "config/memcache.yml"
echo "config/sunspot.yml"
echo "config/initializers/biocat_local.rb"
echo "config/initializers/mail.rb"
echo "config/initializers/secret_token.rb"
echo "data/service_categories.yml"
echo "app/assets/stylesheets/colours/override.css.scss"

echo "Done."
exit 0


