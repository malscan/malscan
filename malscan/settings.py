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
from os import path
import sys
import json
from malscan.error import Error


class Settings:
    def __init__(self):
        self.settings = {}
        self.exception = Error()
        self.base_path = path.dirname(path.dirname(__file__))

        with open(self.base_path + "/malscan/static/settings.json") as s_data:
            self.settings_options = json.load(s_data)

        with open(self.base_path + "/malscan/static/optargs.json") as o_data:
            self.optargs = json.load(o_data)

    def load(self):
        self.settings['base_path'] = self.base_path
        user_home = path.expanduser("~")
        self.local_settings = user_home + "/.config/malscan/malscan.conf"
        self.global_settings = self.base_path + "/config/malscan.conf"

        if path.isfile(self.global_settings):
            self._load_settings_file()
        else:
            Exception.error(
                "The malscan settings file "
                "cannot be found at {}".format(self.global_settings)
            )
            sys.exit(1)

        if path.isfile(self.local_settings):
            self._load_settings_file('local')
            self.settings_file = self.local_settings
            self.settings_mode = 'local'
        else:
            self.settings_file = self.global_settings
            self.settings_mode = 'global'

        self.settings['last_db_update'] = 'placeholder'

    def get(self, settings_option):
        return self.settings[settings_option]

    def show(self):
        json.dump(self.settings, sys.stdout, indent=4)
        print("")

    def _load_settings_file(self, locale='global'):
        if locale == 'local':
            settings_file = self.local_settings
        else:
            settings_file = self.global_settings

        file = open(settings_file, 'r')
        for line in file.readlines():
            self._parse_file_line(line, locale)

    def _parse_file_line(self, line, locale):
        if line[0] == '#':
            return None
        else:
            option = str.strip(line).split()
            if option != []:
                key = option[0]
                value = option[1]
                self._save_settings_option(key, value, locale)

    def _save_settings_option(self, key, value, locale):
        if self._validate_settings_option(key, value, locale):
            self.settings[key] = value

    def _validate_settings_option(self, key, value, locale):
        if key in self.settings_options:
            if self.settings_options[key] == []:
                return True
            elif value in self.settings_options[key]:
                return True
            else:
                settings_values = '\n'.join(self.settings_options[key])
                warning = (
                    "The value {} cannot be set for the settings "
                    "option {}. Available settings values: {}"
                ).format(value, key, settings_values)

                if locale == 'local':
                    self.exception.warning(warning)
                else:
                    self.exception.error(warning)
                return False
        else:
            self.exception.warning(
                "The option {} does not exist "
                "and could not be set.".format(key)
            )
            return False