#!/bin/bash
resolvectl dns ldap-krb5-nfs $(lxc network get ldap-krb5-nfs ipv4.address | cut -d'/' -f1)
resolvectl domain ldap-krb5-nfs '~knfs.local'