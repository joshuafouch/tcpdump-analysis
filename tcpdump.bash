#!/bin/bash

# this script will be used in the crontab -e. cron will call this script every 10 minutes.

sudo tcpdump -ac 100

# end script
