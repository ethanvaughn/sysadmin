#!/bin/bash

# Dump a ps list of all the top-level otranpost process. 

ps -eo ppid,pid,vsize,rss,cmd --sort=pid | grep "[o]tranpost" | head -n1
