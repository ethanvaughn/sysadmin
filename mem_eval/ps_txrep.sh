#!/bin/bash

# Dump a ps list of all the top-level child otxserv procs

. ~/mem_eval/posfunctions

parent_id=$(tl_txrep_pid)
if [ ! -z $parent_id ]; then
	ps -eo ppid,pid,vsize,rss,cmd --sort=pid | grep [t]xrep | grep "^[ ]*${parent_id}[ ]"
fi
