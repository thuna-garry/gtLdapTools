#! /usr/local/bin/python

import os

###################################################################################
# global constants
###################################################################################
modifiedOn="2012-09-03"
modifiedBy="Garry Thuna"


###################################################################################
# local server specific constants
###################################################################################
LOCAL_OS = 'bsd'                #must be either 'linux' or 'bsd'
ORGANIZATION = 'globalBotanical'
DOMAIN = 'globalBotanical.com'
SERVER_SHORT_NAME = 'dirSrv1.yyz'
MASTER_SHORT_NAME = 'dirSrv1.yyz'


###################################################################################
# directory (domain) constants
###################################################################################
SERVER_FQDN = SERVER_SHORT_NAME + '.' + DOMAIN
MASTER_FQDN = MASTER_SHORT_NAME + '.' + DOMAIN

BASE_DN         = 'o=' + ORGANIZATION
BASE_DN_SERVER  = 'gtsName=' + SERVER_SHORT_NAME + ',ou=servers,' + BASE_DN

BIND_URI = 'ldapi://'
BIND_DN  = 'uid=serverAuth,ou=bindAccounts,gtsName=' + SERVER_SHORT_NAME + ',ou=servers,' + BASE_DN
BIND_PW  = 'g6pRbXaW9bWH'

USER_DN_FMT  = 'uid={0},ou=users,' + BASE_DN
GROUP_DN_FMT = 'cn={0},ou=groups,' + BASE_DN
MAIL_DOMAIN = DOMAIN

MIN_UID_NUMBER = 7002    #7001=admin
MIN_GID_NUMBER = 6002    #6001=staff


###################################################################################
# OS specific constants
###################################################################################
GT_TOOLS_DIR = os.path.dirname(os.path.realpath(__file__ ))

TMP_DIR = '/tmp'
OPENLDAP_DIR = '/usr/local/etc/openldap'


###################################################################################
# acl templates
###################################################################################
ACL_NFSV4_WORKSPACE = '{tag}:{qualifier}:rwxpD-a-R-----:fd----:allow'
ACL_NFSV4_WORKSPACE_TRAILER = '''
        everyone@:full_set:fd----:deny
           owner@:--------------:fd----:allow
           group@:--------------:fd----:allow
        everyone@:--------------:fd----:allow
   '''

ACL_NFSV4_USERDIR = '''
           owner@:{qualifier}:r-x---a-R-----:fd----:allow
        everyone@:full_set:fd----:deny
           group@:--------------:fd----:allow
        everyone@:--------------:fd----:allow
   '''

ACL_NFSV4_HOMEDIR = '''
           owner@:{qualifier}:rwxpDda-R-c---:fd----:allow
        everyone@:full_set:fd----:deny
           group@:--------------:fd----:allow
        everyone@:--------------:fd----:allow
   '''


###################################################################################
# these are only needed if server will be running samba
###################################################################################
#SAMBA_DOMAIN    = SERVER_SHORT_NAME
#SAMBA_DOMAIN_DN = 'sambaDomainName=' + SAMBA_DOMAIN + ',' + BASE_DN

SAMBA_SID_PREFIX = 'S-1-5-21-12345-1'

SAMBA_ROOT      = '/data/sambaFiles'
SAMBA_HOME      = SAMBA_ROOT + '/home'
SAMBA_WORKSPACE = SAMBA_ROOT + '/workspace'
SAMBA_USER_HOME = 'personal'

SAMBA_HOME_CONF = 'smb_home.conf'
SAMBA_HOME_TEMPLATE = '''
[{shareName}]
        comment = {shareComment}
        path = {sharePath}
        browseable = no
        writable = yes

        inherit acls = yes
        ;force create mode = 0660
        create mask = 0600
        ;force directory mode = 2770
        directory mask = 2700

        hide dot files = yes
        hide special files = yes
        veto files = /.*/

        follow symlinks = yes
        wide links = yes

        ;valid users = %S
        ;valid users = MYDOMAIN\%S

        ;oplocks = False
        ;level2 oplocks = False

        vfs object = recycle
        recycle:repository = ''' + SAMBA_USER_HOME + '''/_recycleBin
        recycle:keeptree = yes
        recycle:versions = yes
        ;name = _recycleBin
        ;mode = KEEP_DIRECTORIES|VERSIONS|TOUCH
        ;maxsize = 0
        ;exclude = *.tmp|*.temp|*.o|*.obj|~$*|*.~??|*.log|*.trace
        ;excludedir = /tmp|/temp|/cache
        ;noversions = *.doc|*.ppt|*.dat|*.ini

'''

SAMBA_WORKSPACE_CONF = 'smb_workspace.conf'
SAMBA_WORKSPACE_TEMPLATE = '''
[{shareName}]
        comment = {shareComment}
        path = {sharePath}
        browseable = no
        writable = yes

        inherit acls = yes
        ;force create mode = 0660
        ;create mask = 0660
        force directory mode = 2770
        directory mask = 2770

        hide dot files = yes
        hide special files = yes
        veto files = /.*/

        follow symlinks = yes
        wide links = yes

        ;valid users = %S
        ;valid users = MYDOMAIN\%S

        ;oplocks = False
        ;level2 oplocks = False

        vfs object = recycle
        recycle:repository = _recycleBin
        recycle:keeptree = yes
        recycle:versions = yes
        ;name = _recycleBin
        ;mode = KEEP_DIRECTORIES|VERSIONS|TOUCH
        ;maxsize = 0
        ;exclude = *.tmp|*.temp|*.o|*.obj|~$*|*.~??|*.log|*.trace
        ;excludedir = /tmp|/temp|/cache
        ;noversions = *.doc|*.ppt|*.dat|*.ini

'''



###################################################################################
# tls/ssl certificate setup
#   certs can be specified here or picked up from the /etc/openldap/ldap.conf file
#   (guess the python-ldap was compiled againt openLdap libraries)
###################################################################################
import ldap

#-----------
# TLS-related options have to be set globally since the TLS context is only initialized once
#-----------

# directories don't seem to work so
# file will have to contain all/all trusted CA certs
#CACERTFILE = OPENLDAP_DIR + "/cacerts/" + ORGANIZATION + "-cacert.pem"

# Force cert validation
ldap.set_option(ldap.OPT_X_TLS_REQUIRE_CERT, ldap.OPT_X_TLS_DEMAND)
ldap.set_option(ldap.OPT_X_TLS_DEMAND, True)

# Set path name of file containing all trusted CA certificates
ldap.set_option(ldap.OPT_X_TLS_CACERTFILE, OPENLDAP_DIR + "/cacerts/" + ORGANIZATION + "-cacert.pem")
ldap.set_option(ldap.OPT_X_TLS_CERTFILE,   OPENLDAP_DIR + "/certs/"   + SERVER_FQDN  + "-cert.pem")
ldap.set_option(ldap.OPT_X_TLS_KEYFILE,    OPENLDAP_DIR + "/certs/"   + SERVER_FQDN  + "-key.pem")


###################################################################################
# if this file is run as a python script then have it simply print out the value
# of its variables in shell (bash) format
###################################################################################
if __name__ == "__main__":
    import sys
    if len(sys.argv) > 1:
        vars = set(sys.argv) & set(dir())
    else:
        vars = [ x for x in dir() if x[0].isupper()]
    for var in vars:
        lines = eval(var).replace("\n", "\\\n")
        print var + '="' + lines + '"'

