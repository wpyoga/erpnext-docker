#!/bin/sh

. ./private.env

sh dns-update-${DNS_PROVIDER}.sh

