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


class Configuration:
    def __init__(self):
        self.configuration = {}
        self.exception = Error()
        self.base_path = path.dirname(path.dirname(__file__))

        self.config_options = {
            'ApplicationUser':      [],
            'ApplicationGroup':     [],
            'SignatureDirectory':   [],
            'EmailNotifications':   [],
            'NotificationAddress':  [],
            'MalscanSenderAddress': [],
            'QuarantineDirectory':  [],
            'QuarantineMode':       [
                'locked-down',
                'normal'
            ],
            'QuarantineUser':       [],
            'QuarantineGroup':      []
        }

        self.optargs = {
            'l':      'scan.string',
            'm':      'scan.mime',
            's':      'scan.basic',
            'q':      'scan.quarantine',
            't':      'tripwire.scan',
            'w':      'tripwire.whitelist',
            'config':  'core.config',
            'update':  'core.update',
            'version': 'core.version'
        }

    def load(self):
        self.configuration['base_path'] = self.base_path
        user_home = path.expanduser("~")
        self.local_config = user_home + "/.config/malscan.conf"
        self.global_config = self.base_path + "/config/malscan.conf"

        if path.isfile(self.global_config):
            self._load_configuration_file()
        else:
            Exception.error(
                "The malscan configuration file "
                "cannot be found at {}".format(self.global_config)
            )
            sys.exit(1)

        if path.isfile(self.local_config):
            self._load_configuration_file('local')
            self.configuration_file = self.local_config
            self.configuration_mode = 'local'
        else:
            self.configuration_file = self.global_config
            self.configuration_mode = 'global'

        self.configuration['last_db_update'] = 'placeholder'

    def get(self, config_option):
        return self.configuration[config_option]

    def show(self):
        json.dump(self.configuration, sys.stdout, indent=4)
        print("")

    def _load_configuration_file(self, locale='global'):
        if locale == 'local':
            configuration_file = self.local_config
        else:
            configuration_file = self.global_config

        file = open(configuration_file, 'r')
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
                self._save_configuration_option(key, value, locale)

    def _save_configuration_option(self, key, value, locale):
        if self._validate_configuration_option(key, value, locale):
            self.configuration[key] = value

    def _validate_configuration_option(self, key, value, locale):
        if key in self.config_options:
            if self.config_options[key] == []:
                return True
            elif value in self.config_options[key]:
                return True
            else:
                config_values = '\n'.join(self.config_options[key])
                warning = (
                    "The value {} cannot be set for the configuration "
                    "option {}. Available configuration values: {}"
                ).format(value, key, config_values)

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

    # Sanity checks Malscan configuration options
    def _sanity_check(self, option, value, locale):

        if option in self.config_options:
            if self.config_options[option] == []:
                return True
            else:
                if value in self.config_options[option]:
                    return True
                else:
                    config_values = '\n'.join(self.config_options[option])
                    warning = (
                        "The value {} cannot be set for the configuration"
                        "option {}. Available configuration values: {}"
                    ).format(value, option, config_values)

                    if locale == 'local':
                        self.exception.warning(warning)
                    else:
                        self.exception.error(warning)
                    return False
        else:
            self.exception.warning(
                "The option {} does not exist "
                "and could not be set".format(option)
            )
            return False
