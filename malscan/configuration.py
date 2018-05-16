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
from malscan.exception import Exception


class Configuration:
    def __init__(self):
        self.configuration = {}
        self.exception = Exception()
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
            self._load_config_file()
        else:
            Exception.error(
                "The malscan configuration file "
                "cannot be found at {}".format(self.global_config)
            )
            sys.exit(1)

        if path.isfile(self.local_config):
            self._load_config_file('local')
            self.configuration_file = self.local_config
            self.configuration_mode = 'local'
        else:
            self.configuration_file = self.global_config
            self.configuration_mode = 'global'

        self.configuration['last_database_update'] = 'placeholder'

    def get(self, config_option):
        return self.configuration[config_option]

    def show(self):
        print(self.configuration)

    def _load_config_file(self, locale='global'):
        # Saving configuration values
        if locale == 'local':
            config_file = self.local_config
        else:
            config_file = self.global_config

        file = open(config_file, 'r')
        for line in file.readlines():
            if line[0] != "#":
                option = str.strip(line).split()
                if option != []:
                    if self._sanity_check(option[0], option[1], locale):
                        self.configuration[option[0]] = option[1]
        file.close()

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
