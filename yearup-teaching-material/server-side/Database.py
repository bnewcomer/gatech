#!/usr/bin/python
#
# Database is a versatile python class that can connect to multiple
# types of databases. This class is the lowest level abstraction of
# database interaction and can be injected into objects that need to
# interact with a database. Currently supports: MySQL
#
# author: Benjamin Newcomer
# benjaminnewcomer.com
# version: 0.1
# last modified: 12-3-2014

import MySQLdb 
import sys

class Database:

    # __init__ initializes a Database object and attempts to connect
    # to a database. See Database.__connect__() for details on the format
    # of dbType and kwargs
    def __init__(self, dbType, **kwargs):

        # initalize the database
        self._link = None
        self._linkType = dbType

        #attempt to connect to a database
        self.__connect__(dbType, **kwargs)

        
    # __connect__  attempts to connect to a database. 
    # dbType specifies the type of database to connect
    # to. Accepted values are: "mysql". conArgs is a dictionary that
    # contains the entries needed to connect to the database. If connection
    # is unsuccessful, the database object will have a null link
    def __connect__(self, dbType, **kwargs):

        # create the appropriate database connection based on dbType
        if dbType == "mysql":

            # check if correct args are present
            argsPresent = 'host' in kwargs \
                and 'username' in kwargs \
                and 'password' in kwargs \
                and 'dbName' in kwargs

            if argsPresent:
                self._link = MySQLdb.connect(kwargs['host'],
                 kwargs['username'], kwargs['password'], kwargs['dbName'])
                # set linkType to none if connection was unsuccessful
                if self._link is None: self._linkType = None
            else:
                raise Exception("missing args needed for " + self._linkType + " connection.")
        else:
            raise Exception("dbType None or not supported.")

    # query performs a raw mysql query using the active database connection.
    # This method does not implement any security and should only be used
    # in development. sql is a string to pass to the database. Can only be
    # used with a mysql connection. raises Exception if connection type is 
    # not mysql.
    def query(self, sql):
        # verify that a connection exists
        if self._link is None:
            raise Exception("no connection")
            return False
        # verify that the connection type is mysql
        elif self._linkType != 'mysql':
            raise Exception("mysql connection required. type: " + self._linkType)
            return False
        else:       
            # execute the sql
            cursor = self._link.cursor()
            cursor.execute(sql)
            return cursor.fetchall()

    # close closes the database connection. Most connections are
    # automatically closed when the reference count for the database
    # isntance reaches 0. However, this method can close the connection
    # without the need for the aforementioned condition.
    def close(self):
        # close the connection the appropriate way
        if self._linkType == 'mysql':
            self._link.close()

        # set the link and linkType to None
        self._link = None
        self._linkType = None
            

