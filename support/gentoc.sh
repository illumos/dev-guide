#!/bin/ksh
#
# This file and its contents are supplied under the terms of the
# Common Development and Distribution License ("CDDL"), version 1.0.
# You may only use this file in accordance with the terms of version
# 1.0 of the CDDL.
#
# A full copy of the text of the CDDL should have accompanied this
# source.  A copy of the CDDL is also available via the Internet at
# http://www.illumos.org/license/CDDL.
#

#
# Copyright (c) 2014, Joyent, Inc. 
#

#
# Generate a TOC for a given page for a given document
#

gt_arg0=$(basename $0)
gt_file=
gt_lay=0

function fatal
{
	typeset msg="$*"
	[[ -z "$msg" ]] && msg="failed"
	echo "$gt_arg0: $msg" >&2
	exit 1
}

function print_tab
{
	typeset i
	typeset max=$1
	for ((i = 0; i < $max; i++)); do
		printf "\t"
	done
}

function prologue
{
	printf "<div class=\"span3\">\n"
	printf "<div class=\"well sidebar-nav\">\n"
	printf "<ol class=\"nav nav-list\">\n"
}

function epilogue
{
	printf "</ol>\n"
	printf "</div>\n" # well widebar-nav
	printf "</div>\n" # span3
	printf "<div class=\"span9\">\n"
}

function printlink
{
	typeset file title id
	file=$1
	title=$2
	id=$3
	if [[ -n "$id" ]]; then
		printf "<a href=\"./$file.html#$id\">$title</a>\n"
	else
		printf "<a href=\"./$file.html\">$title</a>\n"
	fi
}

function doline
{
	typeset file level title diff id
	file=$1
	level=$2
	title=$3
	[[ -z "$file" ]] && fatal "missing file"
	[[ -z "$level" ]] && fatal "missing level"
	[[ -z "$title" ]] && fatal "missing title"
	level=$(printf $level | wc -c)
	id=$(echo "$title" | tr -cd " [:alnum:]" | tr ' A-Z' '-a-z')

	#
	# We need to do one of a few things. If we're coming from increasing our
	# layer we need to open a new list and increase the tab. Also if we're
	# going from zero to one, we need to open this for the first time.
	#
	if [[ $level -gt $gt_lay && $gt_lay -eq 0 ]]; then
		printf "\t<li>\n\t"
		printlink "$file" "$title"
		((gt_lay++))
	elif [[ $level -gt $gt_lay ]]; then
		print_tab $gt_lay
		printf "<ul>\n"
		print_tab $level
		printf "<li>\n"
		print_tab $level
		((gt_lay++))
		if [[ $gt_lay -eq 1 ]]; then
			printlink "$file" "$title"
		else
			printlink "$file" "$title" "$id"
		fi
	elif [[ $level -eq $gt_lay ]]; then
		print_tab $level
		printf "</li>\n"	
		print_tab $level
		printf "<li>\n"	
		print_tab $level
		if [[ $gt_lay -eq 1 ]]; then
			printlink "$file" "$title"
		else
			printlink "$file" "$title" "$id"
		fi
	else
		print_tab $gt_lay
		printf "</li>\n"
		while [[ $gt_lay -ne $level ]]; do
			((gt_lay--))
			print_tab $gt_lay
			printf "</ul>\n"
			print_tab $gt_lay
			printf "</li>\n"
		done
		print_tab $level
		printf "<li>\n"
		print_tab $level
		if [[ $gt_lay -eq 1 ]]; then
			printlink "$file" "$title"
		else
			printlink "$file" "$title" "$id"
		fi
	fi
}

#
# We need to do some work. To start with we need to close the most recent item.
# Then after that we need to close every list and potentially item as well down
# the chain. 
#
function cleanup
{
	while [[ $gt_lay -gt 0 ]]; do
		print_tab $gt_lay
		printf "</li>\n"
		((gt_lay--))
		print_tab $gt_lay
		if [[ $gt_lay -ne 0 ]]; then
			printf "</ul>\n"	
		fi
	done
}

function process_file
{
	typeset file
	file=$1
	gt_lay=0
	awk '
	BEGIN{ skip = 0 }

	/```/{ skip++ }

	/^[#]+ /{ if (skip % 2 == 0) { print $0 } }' < $file | \
	     while read line; do
		doline $file "$(echo $line | cut -d' ' -f1)" \
		    "$(echo $line | cut -d' ' -f2-)"
		[[ "$file" != "$gt_file" ]] && break
	done

	cleanup

}

[[ -z "$1" ]] && fatal "missing input file"
gt_file=$1
shift
[[ ! -f "$gt_file" ]] && fatal "argument is not a file: $1"
[[ $# -gt 0 ]] || fatal "<target> file [file ...]"

prologue
while [[ $# -gt 0 ]]; do
	process_file $1
	shift
done
epilogue
