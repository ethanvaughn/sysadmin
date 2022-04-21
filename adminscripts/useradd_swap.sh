#!/bin/bash

# NOTE: Reverses Useradd Tomaxification

if [ "$1" = "untomax" ]
then

# Reverse

    echo "Un-Tomaxifying the user commands"

    /bin/mv /usr/sbin/useradd /usr/sbin/useradd.tmx
    /bin/mv /usr/sbin/userdel /usr/sbin/userdel.tmx
    /bin/mv /usr/sbin/usermod /usr/sbin/usermod.tmx
    
    /bin/mv /usr/sbin/tmxuseradd /usr/sbin/useradd
    /bin/mv /usr/sbin/tmxuserdel /usr/sbin/userdel
    /bin/mv /usr/sbin/tmxusermod /usr/sbin/usermod
    
    echo ""
    echo "WARNING: any users added in the 40000 range will be"
    echo "deleted as soon as central auth runs from cron."
    echo ""
    
    exit 0
fi

# Put back

if [ "$1" = "tomax" ]
then
    echo "Tomaxifying the user commands"
    
    /bin/mv /usr/sbin/useradd /usr/sbin/tmxuseradd
    /bin/mv /usr/sbin/userdel /usr/sbin/tmxuserdel
    /bin/mv /usr/sbin/usermod /usr/sbin/tmxusermod
    
    /bin/mv /usr/sbin/useradd.tmx /usr/sbin/useradd
    /bin/mv /usr/sbin/userdel.tmx /usr/sbin/userdel
    /bin/mv /usr/sbin/usermod.tmx /usr/sbin/usermod

    echo ""
    echo "SUCCESS: The server has been restored to the Tomax config"
    echo ""
    exit 0
fi


# If we make it here we throw usage
echo ""
echo "Usage: useradd_swap <untomax/tomax>"
echo ""
echo "   untomax: remove central auth protection"
echo "   tomax:   add central auth protection back in"


