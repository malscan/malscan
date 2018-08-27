#!/usr/bin/env python
# --------------------------------------------------
#
# Package: Malscan
# Author: Josh Grancell <jgrancell@malscan.com>
# Description: Linux malware scanner
# Copyright: 2015-2018 Josh Grancell
# License: MIT License
#
# --------------------------------------------------
"""
Malscan Help module

:class Help:             provides help functionality to Malscan

:function version:       displays version line
:function display:       displays help text
:function output:        passes help text to correct formatter
:function _print_header: prints the header helptext
:function _print_switch: prints switch helptext
"""
from malscan import __version__


class Help:
    """ This class provides Help functionality for Malscan,
    and catches failing malscan commands and arguments
    """
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
        self.switch_length = 11

    @staticmethod
    def version():
        """ Prints the current malscan and signature versions """
        print(__version__)

    def display(self, last_db_update):
        """ Prints out all available commands, plus version information """
        print("{}, last updated: {}".format(__version__, last_db_update))
        self._print_header('Usage:')
        print("    malscan [parameters] [target]")

        cmd = []
        cmd.append({'Scan Modes:': None})
        cmd.append({'-l': 'suspicious string scanning mode'})
        cmd.append({'-m': 'file extension match scanning mode'})
        cmd.append({'-s': 'basic malware scan'})
        cmd.append({'-q': 'malware quarantine mode'})
        cmd.append({'Tripwire:': None})
        cmd.append(
            {'-t': 'scans target directory for altered whitelisted files'}
        )
        cmd.append({'-w': 'whitelists all files in the target directory'})
        cmd.append({'General Commands:': None})
        cmd.append({'config': 'displays running malscan configuration'})
        cmd.append({'update': 'updates malscan malware signatures'})
        cmd.append({'version': 'shows application and signature versions'})
        for key in cmd:
            for switch, description in key.items():
                self.output(switch, description)

    def output(self, switch, description):
        """ Determines the correct print formatter to use for a help line"""
        if description is None:
            self._print_header(switch)
        else:
            self._print_switch(switch, description)

    def _print_header(self, header):
        """ Prints a header line, non-indented and with a preceeding newline"""
        print("{}{}{}{}".format(
            self.style['newline'],
            self.style['header'],
            header,
            self.style['normal']
        ))

    def _print_switch(self, switch, description):
        """ Prints a switch line, aligning the description with other lines"""
        while len(switch) < self.switch_length:
            switch = switch + ' '
        print('    ' + switch + description)
