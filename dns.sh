#!/bin/bash
resolvectl dns krb5-nfs $(lxc network get krb5-nfs ipv4.address | cut -d'/' -f1)
resolvectl domain krb5-nfs '~knfs.local'