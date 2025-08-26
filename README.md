# ldap-krb5-nfs-on-lxd

This repository provisions 3 VM on LXD using OpenTofu and deploys the following
stack with Ansible:
 - an OpenLDAP backed Kerberos server,
 - an NFS server,
 - and a client to test authentication and NFS.

## Deployment

Provision the LXD VM:

```console
$ cd tofu
$ tofu init
$ tofu apply
```

Resolve the `knfs5.local` domain with the LXD DNS server

```console
$ cd ..
$ sudo ./dns.sh
```

Deploy the stack:


```console
$ cd ansible
$ ansible-playbook playbooks/all.yaml
```

## Usage

###  Create groups and users

In order for user to have both have POSIX and Kerberos attributes, they are created
using `ldapscripts` first, and added Kerberos attributes after.

All commands are run from `krb5` host as `root`.

Create POSIX group and user:

```console
root@krb5:~$ LDAPTLS_REQCERT=never ldapaddgroup <group name>
root@krb5:~$ LDAPTLS_REQCERT=never ldapadduser <user name> <group name>
```

To add Kerberos attributes to an existing LDAP user, the `addprinc` command must
have the `-x` flag with the dn of the user: 

```console
root@krb5:~$ kadmin.local -q "addprinc -x dn=uid=<user name>,ou=People,dc=knfs,dc=local <user name>"
Authenticating as principal root/admin@KNFS.LOCAL with password.
No policy specified for <user name>@KNFS.LOCAL; defaulting to no policy
Enter password for principal "<user name>@KNFS.LOCAL": 
Re-enter password for principal "<user name>@KNFS.LOCAL": 
Principal "<user name>@KNFS.LOCAL" created.
```

### Share folder with NFSv4

Run the commands below from `nfs` host as `root`.

```console
root@nfs:~ mkdir <folder>
root@nfs:~ chown root:<group name> <folder>
root@nfs:~ echo "<folder> *(rw,sync,no_subtree_check,sec=krb5p)" >> /etc/exports
root@nfs:~ exportfs -rav
```

Run the commands below from `client` host as `root`.

```console
root@client:~ mount nfs.knfs.local:<shared folder> <mount folder> 
```

Login with a Kerberos user and use `klist` to see the initial ticket.

```console
root@client:~ login <user>
Password:
<user>@client:/ klist
Ticket cache: FILE:/tmp/krb5cc_10000_q5UoXp
Default principal: <user>@KNFS.LOCAL

Valid starting     Expires            Service principal
08/26/25 13:03:25  08/26/25 23:03:25  krbtgt/KNFS.LOCAL@KNFS.LOCAL
        renew until 08/27/25 13:03:25
```

Explore the shared folder and use `klist`: a new `nfs` ticket was acquired without
password prompt.

```console
<user>@client:/ ls -l <mount folder>
Password:
<user>@client:/ klist
Ticket cache: FILE:/tmp/krb5cc_10000_q5UoXp
Default principal: <user>@KNFS.LOCAL

Valid starting     Expires            Service principal
08/26/25 13:03:25  08/26/25 23:03:25  krbtgt/KNFS.LOCAL@KNFS.LOCAL
        renew until 08/27/25 13:03:25
08/26/25 13:07:50  08/26/25 23:03:25  nfs/nfs.knfs.local@
        renew until 08/27/25 13:03:25
        Ticket server: nfs/nfs.knfs.local@KNFS.LOCAL
```