#!/bin/bash

# Dump a ps list of all the top-level posapisrv procs. 

. ~/mem_eval/posfunctions

parent_id=$(tl_tmxsrvc_pid)
if [ ! -z $parent_id ]; then
	ps -eo ppid,pid,vsize,rss,cmd --sort=pid | grep "posapi" | grep "^[ ]*$parent_id[ ]"
fi
