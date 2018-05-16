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
from os import path, chmod, mkdir
from malscan.help import Help


class Exception:

    def __init__(self):
        self.help = Help()
        self.base_path = path.dirname(path.dirname(__file__))
        self.log_path = "{}/logs".format(self.base_path)
        self.log_file = "{}/error.log".format(self.log_path)

        if not path.isdir(self.log_path):
            mkdir(self.log_path, 0o755)
            chmod(self.log_path, 0o755)

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
        log_string = 'WARNING: {}'.format(string)
        console_string = self._format_string('warning', string)
        if secondary != "":
            secondary = self._format_string('warning', secondary)
        self._handle_exception(console_string, log_string, secondary)

    def error(self, string, secondary=""):
        log_string = 'FATAL ERROR: {}'.format(string)
        console_string = self._format_string('error', string)
        if secondary != "":
            secondary = self._format_string('error', secondary)
        self._handle_exception(console_string, log_string, secondary)

    def _format_string(self, exception_type, string):
        style = self.help.style[exception_type]
        return style + string + self.help.style['normal']
