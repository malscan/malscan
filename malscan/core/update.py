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
from malscan.configuration import Configuration
from os import path, makedirs
from shutil import chown, which


class Update:
    def __init__(self):
        # Loading our configuration into the Updater
        self.config = Configuration()
        self.config.load()
        self.signature_path = self.config.get('SignatureDirectory')
        self.updater_user = self.config.get('ApplicationUser')
        self.updater_group = self.config.get('ApplicationGroup')
        self.freshclam_binary = which("freshclam")

        # Making sure that our signatures directory exists and is writable
        if path.isdir(self.signature_path):
            print('Signatures directory exists')
        else:
            makedirs(self.signature_path, 0o755)
            chown(self.signature_path, self.updater_user, self.updater_group)
            print('Signatures directory has been created.')

    def run(self):
        print('Running the updater')
