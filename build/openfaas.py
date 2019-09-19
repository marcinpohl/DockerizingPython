# -*- coding: utf-8 -*-
# @Author: cody
# @Date:   2019-09-18 11:20:31
# @Last Modified by:   cody
# @Last Modified time: 2019-09-18 13:04:41


import os, traceback, urllib.parse
import logging as log
import cherrypy, requests

log.root.setLevel(log.DEBUG)


if 'OPENFAAS_URL' in os.environ:
    OPENFAAS_URL = os.environ['OPENFAAS_URL']
else:
    OPENFAAS_URL = 'http://127.0.0.1:8080'

log.debug('OPENFAAS_URL - %s', OPENFAAS_URL)

assert '://' in OPENFAAS_URL, OPENFAAS_URL

def verify_non_empty_string(s):
    ''' shortcut for asserting that a variable is a non-empty string '''
    assert isinstance(s, str), s
    assert s.strip(), s

def html_friendly_exception(ex):
    '''returns a browser friendly view for a crash'''
    log.exception(ex)
    return ''.join(
        traceback.format_exception(
            type(ex),
            ex,
            ex.__traceback__
        )
    ).replace('\n', '<br/>')

def request(f, q=None):
    ''' maps url parameters to valid request data and returns the faas result '''
    try:
        yield from requests.get(
            '{}/function/{}'.format(OPENFAAS_URL, f),
            **({} if q is None else {'data':q})
        )
    except Exception as ex:
        yield html_friendly_exception(ex)

class RequestGateway(object):
    ''' contains all all logic for the server '''
    @cherrypy.expose
    def index(self, f, q=None):
        verify_non_empty_string(f)
        if q is not None:
            verify_non_empty_string(q)
            log.debug('before url parse - %s', q)
            q = urllib.parse.unquote(q)
            log.debug('after url parse - %s', q)

        yield from request(f, q)


cherrypy.config.update({
    'server.socket_host': '0.0.0.0',
    'server.socket_port': 8080
})

if __name__ == '__main__':
    cherrypy.quickstart(RequestGateway())
#    import sys
#    import threading
#    sys.setrecursionlimit(100)
#    threading.stack_size(0x200000000)
#    t = threading.Thread(target=cherrypy.quickstart(RequestGateway()))
#    t.start()
#    t.join()
