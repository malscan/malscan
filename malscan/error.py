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
from os import path, mkdir
from malscan.help import Help


class Error:

    def __init__(self):
        self.help = Help()
        self.base_path = path.dirname(path.dirname(__file__))
        self.log_path = "{}/logs".format(self.base_path)
        self.log_file = "{}/error.log".format(self.log_path)

        if not path.isdir(self.log_path):
            mkdir(self.log_path, 0o755)

    def _log_writer(self, string):
        file = open(self.log_file, 'a+')
        file.write(string + '\n')
        file.close()

    def _handle_exception(self, console_string, log_string, secondary=""):
        print(console_string)
        if secondary != "":
            print(secondary)
        self._log_writer(log_string)

    def warning(self, string, secondary=""):
        self.error(string, secondary, False)

    def error(self, string, secondary="", fatal=True):
        if fatal:
            error_string = 'ERROR'
        else:
            error_string = 'WARNING'
        log_string = error_string + ': {}'.format(string)
        console_string = self._format_string(error_string.lower(), string)
        if secondary != '':
            secondary = self._format_string(error_string.lower(), secondary)
        self._handle_exception(console_string, log_string, secondary)

    def _format_string(self, exception_type, string):
        style = self.help.style[exception_type.lower()]
        return style + string + self.help.style['normal']
