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
        self._print_header('Usage:')
        print("    malscan [parameters] [target]")

        switches = {
            'Scan Modes:': None,
            '-l': 'suspicious string scanning mode',
            '-m': 'file extension match scanning mode',
            '-s': 'basic malware scan',
            '-q': 'malware quarantine mode',
            'Tripwire:': None,
            '-t': 'scans the target directory for altered whitelisted files',
            '-w': 'whitelists all files in the target directory',
            'General Commands:': None,
            'config': 'displays the current running malscan configuration',
            'update': 'updates malscan with the latest malware signatures',
            'version': 'shows the current application and signature versions'
        }
        for switch, description in switches.items():
            self.output(switch, description)

    def output(self, switch, description):
        if description is None:
            self._print_header(switch)
        else:
            self._print_switch(switch, description)

    def _print_header(self, header):
        print("{}{}{}{}".format(
            self.style['newline'],
            self.style['header'],
            header,
            self.style['normal']
        ))

    def _print_switch(self, switch, description):
        switch_size = len(switch)
        if switch_size == 7:
            switch_padding = '    '
        elif switch_size == 6:
            switch_padding = '     '
        else:
            switch_padding = '         '
        print('    ' + switch + switch_padding + description)
