#!/usr/bin/env python
# --------------------------------------------------
#
# Package: Malscan
# Author: Josh Grancell <jgrancell@malscan.org>
# Description: Linux malware scanner
# Copyright: 2015-2018 Josh Grancell
# License: MIT License
#
# --------------------------------------------------
from malscan import __version__


class Help:
    def __init__(self):
        self.style = {}
        self.style['header'] = '\033[95m'
        self.style['info'] = '\033[94m'
        self.style['success'] = '\033[92m'
        self.style['warning'] = '\033[93m'
        self.style['error'] = '\033[91m'
        self.style['normal'] = '\033[0m'
        self.style['bold'] = '\033[1m'
        self.style['underline'] = '\033[4m'
        self.style['newline'] = '\n'

    def version(self):
        print(__version__)

    def display(self, last_db_update):
        print("{}, last updated: {}".format(
            __version__,
            last_db_update)
        )
        self._pheader('Usage:')
        print("    malscan [parameters] [target]")
        self._pheader('Scan Modes:')
        self._pswitch(
            '-l',
            'suspicious string scanning mode'
        )
        self._pswitch(
            '-m',
            'file extention match scanning mode'
        )
        self._pswitch(
            '-s',
            'basic malware scan [implied when you provide no other modes]'
        )
        self._pswitch(
            '-q',
            'malware quarantine mode'
        )
        self._pheader('Tripwire:')
        self._pswitch(
            '-t',
            'scans the target directory for altered whitelisted files'
        )
        self._pswitch(
            '-w',
            'whitelists all files in the target directory'
        )
        self._pheader('Other Modes:')
        self._pswitch(
            'config',
            'displays the current running malscan configuration'
        )
        self._pswitch(
            'update',
            'updates malscan with the latest malware signatures'
        )
        self._pswitch(
            'version',
            'shows the current application and signature versions'
        )

    def _pheader(self, header):
        print("{}{}{}{}".format(
            self.style['newline'],
            self.style['header'],
            header,
            self.style['normal']
        ))

    def _pswitch(self, switch, description):
        switch_size = len(switch)
        if switch_size == 7:
            switch_padding = '    '
        elif switch_size == 6:
            switch_padding = '     '
        else:
            switch_padding = '         '
        print('    ' + switch + switch_padding + description)
