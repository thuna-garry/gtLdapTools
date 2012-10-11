#! /usr/local/bin/python

import sys
import os
import ldap
import subprocess
import tempfile
from optparse import OptionParser

sys.path.append(os.path.realpath(os.path.join(__file__, '..', '..', 'conf')))
from ldapConf import *


###################################################################################
# global constants
####################################################################################
version="%prog: 2012-09-26"
modifiedBy="Garry Thuna"


###################################################################################
# utility:  exract a specific attribute value from a DN
###################################################################################
def getDNattr(dn, attr):
    pieces = [ a for a in dn.split(',') if a.find(attr) > -1 ]
    if len(pieces):
        return pieces[0].split('=')[1]
    else:
        return ''


###################################################################################
# utility:  set the ownership and permissions of a file/directory
###################################################################################
def setOwnerGroupPerms(path, owner, group, perms):
    og = owner + ':' + group
    p = subprocess.Popen([ "chown", "-h", og, path ]); p.wait()
    if p.returncode:
        print >> sys.stderr, '  *** Error setting ownership: (' + og + ') on ' + path

    # set the path permissions
    os.chmod(path, perms)


###################################################################################
# utility:  derive the qualified gtWorkspaceName <gtsName>/<gtwsName>
#           rec must be of objectClass=gtWorkspace
###################################################################################
def getQualGtwsName(gtwsRec):
    dn, attrs = gtwsRec
    return getDNattr(dn, 'gtsName') + ':' +  attrs['gtwsName'][0] 


###################################################################################
# utility:  convert the zipped linked file contents of gtwsLinkFile attributes
#           to unzipped format
###################################################################################
def unzipGtwsLinkFile(rec):
    dn, attrs = rec
    if 'gtwsLinkFile' in attrs:
        # write the attribute contents (the zipfile) out to a temp file
        fd, fname = tempfile.mkstemp(suffix='.zip',dir='/tmp')
        f = open(fname, 'w')
        f.write(attrs['gtwsLinkFile'][0])
        f.flush()
        f.close
        os.close(fd)

        # extract the contents into an empty temporary directory
        tmpdir = tempfile.mkdtemp(dir='/tmp')
        p = subprocess.Popen([ "unzip", "-qd", tmpdir, fname]); p.wait()
        if p.returncode:
            print >> sys.stderr, '  *** Error unzipping gtwsLinkFile from dn: ' + dn

        # replace the attribute oontents with the binary link file
        with open(os.path.join(tmpdir, os.listdir(tmpdir)[0]), 'r') as f:
            attrs['gtwsLinkFile'][0] = f.read(2048)
       
        # cleanup temporary objects
        p = subprocess.Popen([ "rm", "-f", fname]); p.wait()
        p = subprocess.Popen([ "rm", "-rf", tmpdir]); p.wait()


###################################################################################
# determining available/used uid & gid numbers
###################################################################################
def maxUsedGidNumber(groups):
    maxGidNumber = 0
    for g in groups:
        cur = int(g[1]['gidNumber'][0])
        if cur > maxGidNumber:
            maxGidNumber = cur
    return maxGidNumber

def maxUsedUidNumber(users):
    maxUidNumber = 0
    for u in users:
        cur = int(u[1]['uidNumber'][0])
        if cur > maxUidNumber:
            maxUidNumber = cur
    return maxUidNumber

def firstUnusedGidNumber(groups):
    sg = sorted([ int(g[1]['gidNumber'][0]) for g in groups ])
    n = MIN_GID_NUMBER
    while n in sg:
        n = n + 1
    return n

def firstUnusedUidNumber(users):
    su = sorted([ int(u[1]['uidNumber'][0]) for u in users ])
    n = MIN_UID_NUMBER
    while n in su:
        n = n + 1
    return n


###################################################################################
# the ldap queries
###################################################################################
def queryUserGroup(con):
    baseDN = BASE_DN
    filter = '(|(objectClass=posixAccount)(objectClass=posixGroup))'
    attrs  = [ 'uidNumber', 'uid', 'cn', 'gidNumber', 'memberUid', 'sambaHomePath' ]
    qr = con.search_s( baseDN, ldap.SCOPE_SUBTREE, filter, attrs )
    return qr

def queryWorkspace(con):
    baseDN = BASE_DN
    filter = '(&(objectClass=gtWorkspace)(gtwsName=*))'
    attrs  = [ 'gtwsName', 'gtwsRelativePath', 'gtwsACL', 'gtwsLinkFile'
             , 'gtwsOwnerUid', 'gtwsAdministratorUid', 'gtwsHasRecycleBin'
             , 'description' ]
    qr = con.search_s( baseDN, ldap.SCOPE_SUBTREE, filter, attrs )
    return qr

def queryServer(con):
    baseDN = BASE_DN
    filter = '(objectClass=gtServer)'
    attrs  = [ 'gtsName', 'gtsFQDN', 'gtsNickname' ]
    qr = con.search_s( baseDN, ldap.SCOPE_SUBTREE, filter, attrs )
    return qr


###################################################################################
# given a workspace record return its canonical server path 
###################################################################################
def getWorkspaceRelativePath(con, workspace):
    dn, attrs = workspace

    # split the dn into its pieces and then query for all ancestral 
    # workspaces (inclusive) 
    pieces = dn.split(',')   # split the DN into its component pieces
    filter=""
    i=0
    while pieces[i].startswith('gtwsName'):
        filter = filter + '(' + pieces[i]  + ')'
        i += 1
    filter="(|" + filter + ")"
    baseDN = ",".join(pieces[i:])
    attrs  = [ 'gtwsRelativePath' ]
    qr = con.search_s( baseDN, ldap.SCOPE_SUBTREE, filter, attrs )
    workspaces = sorted( qr, key=lambda r: ','.join(r[0].split(',')[::-1]).lower() )

    path = ""
    for ws in workspaces:
        path = os.path.join( path, ws[1]['gtwsRelativePath'][0] )
    return path


###################################################################################
# process users and groups
#    build up a set of cross references to user, group, workspace and server
###################################################################################
def preProcessLdapObjects(con):

    ###############################################################################
    # start with the user and group info
    ###############################################################################
    qr = queryUserGroup(con)
    qrSorted = sorted( qr, key=lambda r: ','.join(r[0].split(',')[::-1]).lower() )
    groups = [ r for r in qrSorted if r[0].lower().find(',ou=groups,') + 1 ]
    users  = [ r for r in qrSorted if r[0].lower().find(',ou=users,') + 1 ]

    # build a gid to groups' index mapping
    gid2group = dict()
    for g in groups:
        gid2group[g[1]['cn'][0]] = g

    # build a uid to users' index mapping
    uid2user = dict()
    for u in users:
        uid2user[u[1]['uid'][0]] = u

    # build a gnum to groups' index mapping
    gnum2group = dict()
    for g in groups:
        gnum2group[g[1]['gidNumber'][0]] = g

    #resolve each user's primarty group and add the uid to that group's memberUid list
    for u in users:
        try:
            gAttrDict = gnum2group[ u[1]['gidNumber'][0] ][1]
        except KeyError, e:
            print >>sys.stderr, "DN: " + u[0] + "\n" +\
                                "    has gidNumber '" + u[1]['gidNumber'][0] + "' which was not found."
            continue
        if 'memberUid' not in gAttrDict: 
            gAttrDict['memberUid'] = list()
        gAttrDict['memberUid'].append( u[1]['uid'][0] )

    #create a belongsTo dictionary for each user's group memberships
    #entries are of the form uid:[gid, gid, ...]
    belongsTo = dict()
    for g in groups:
        if 'memberUid' not in g[1]:    #group has no members
            continue
        muids = g[1]['memberUid']
        for m in [m for m in muids]:   #list comprehension allows orig list to be mutated
            try:
                exists = uid2user[m]
            except KeyError, e:
                print >>sys.stderr, "DN: " + g[0] + "\n" +\
                                    "    has memberUid '" + m + "' which was not found."
                del muids[muids.index(m)]  #remove the erroneous entry
            if m not in belongsTo:
                belongsTo[m] = list()
            belongsTo[m].append( g[1]['cn'][0] )


    ###############################################################################
    # now lets do the workspaces
    ###############################################################################
    qr = queryWorkspace(con)
    workspaces = sorted( qr, key=lambda r: ','.join(r[0].split(',')[::-1]).lower() )

    # build a name to workspace mapping and along the way
    # unzip any gtwsLinkFile attributes
    gtwsName2ws = dict()
    for ws in workspaces:
        gtwsName2ws[getQualGtwsName(ws)] = ws
        unzipGtwsLinkFile(ws)

    # build a name to path mapping, where path will be a (dn, relativePath) tuple
    gtwsName2path = dict()
    for i in xrange(len(workspaces)):
        ws = workspaces[i]; dn, attrs = ws
        qualGtwsName = getQualGtwsName(ws)
        gtwsName2path[qualGtwsName] = ( qualGtwsName.split(':')[0], attrs['gtwsRelativePath'][0] )
        for j in xrange(i-1, 0-1, -1):
            pp = workspaces[j]; ppdn, ppattrs = pp       #pp: possibleParent
            ppQualGtwsName = getQualGtwsName(pp)
            if dn.lower().endswith(ppdn.lower()):
                gtwsName2path[qualGtwsName] = ( qualGtwsName.split(':')[0],
                                              os.path.join( gtwsName2path[ppQualGtwsName][1] ,
                                                            gtwsName2path[qualGtwsName][1]   ) )
                break

    # build a gidNumber to gtwsName list - basically what gtws(s) have acls referring to the group
    #   and a uid       to gtwsName list - basically what gtws(s) have acls referring to the user
    gid2gtwsName = dict()
    uid2gtwsName = dict()
    for ws in workspaces:
        dn, attrs = ws
        for acl in attrs['gtwsACL']:
            if acl.lower().startswith('group:'):
                gid = acl.split(':')[1]
                try:                           # sanity check that the gid is valid
                    exists = gid2group[gid]
                except KeyError, e:
                    print >>sys.stderr, "DN: " + dn + "\n" +\
                                        "    has acl referring to group '" + gid + "' which was not found."
                    continue
                if gid not in gid2gtwsName:
                    gid2gtwsName[gid] = list()
                gid2gtwsName[gid].append( getQualGtwsName(ws) )
            if acl.lower().startswith('user:'):
                uid = acl.split(':')[1]
                try:                           # sanity check that the uid is valid
                    exists = uid2user[uid]
                except KeyError, e:
                    print >>sys.stderr, "DN: " + dn + "\n" +\
                                        "    has acl referring to user '" + uid + "' which was not found."
                    continue
                if uid not in uid2gtwsName:
                    uid2gtwsName[uid] = list()
                uid2gtwsName[uid].append( getQualGtwsName(ws) )


    ###############################################################################
    # now lets do the servers
    ###############################################################################
    qr = queryServer(con)
    servers = sorted( qr, key=lambda r: ','.join(r[0].split(',')[::-1]).lower() )

    # build a gtsName to server mapping
    gtsName2server = dict()
    for s in servers:
        gtsName2server[ s[1]['gtsName'][0] ] = s


    ###############################################################################
    # that's all we need
    ###############################################################################
    return groups, users, gid2group, uid2user, belongsTo                        \
         , workspaces, gtwsName2ws, gtwsName2path, gid2gtwsName, uid2gtwsName   \
         , servers, gtsName2server


def main():
    ##############################################################################
    # parse command line options
    ##############################################################################
    usage = "usage: %prog [options]" 
    description = "Checks references between users, groups, and acls"
    parser = OptionParser(usage=usage, version=version, description=description)
    (options, args) = parser.parse_args()


    ###############################################################################
    # bind to the ldap server
    #     do the preliminary procssing of users and groups
    #     do the preliminary procssing of workspaces
    ###############################################################################
    con = ldap.initialize(BIND_URI)
    if BIND_TLS:
        con.start_tls_s()
    con.simple_bind_s(BIND_DN, BIND_PW)

    groups,                \
        users,             \
         gid2group,        \
         uid2user,         \
         belongsTo,        \
        workspaces,        \
         gtwsName2ws,      \
         gtwsName2path,    \
         gid2gtwsName,     \
         uid2gtwsName,     \
        servers,           \
         gtsName2server  = preProcessLdapObjects(con)
    con.unbind_s()

if __name__ == "__main__":
    sys.exit(main())

