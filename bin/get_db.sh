#!/usr/bin/env bash

heroku pg:backups:capture &&
    heroku pg:backups:download -o latest.dump &&
    dropdb blockchain_development &&
    createdb blockchain_development &&
    pg_restore -d blockchain_development latest.dump
