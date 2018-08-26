# -*- encoding: utf-8 -*-
# pylint: skip-file
import unittest
from os import path
from malscan.app import Malscan


class TestMalscan(unittest.TestCase):
    def setUp(self):
        self.malscan = Malscan()
        self.maxDiff = None
        self.base_path = path.dirname(path.dirname(__file__))

    def test_settings(self):

        expected = {
            "base_path": self.base_path,
            "ApplicationUser": "malscan",
            "ApplicationGroup": "malscan",
            "SignatureDirectory": "/opt/malscan/signatures",
            "EmailNotifications": "false",
            "NotificationAddress": "root",
            "MalscanSenderAddress": "malscan@yourhostname",
            "QuarantineDirectory": "/opt/malscan/quarantine",
            "QuarantineMode": "locked-down",
            "QuarantineUser": "root",
            "QuarantineGroup": "malscan",
            "last_db_update": "placeholder",
        }
        settings = self.malscan.settings.settings
        self.assertDictEqual(expected, settings)

    def test_optargs(self):
        expected_optargs = {
            "l": "scan.string",
            "m": "scan.mime",
            "s": "scan.basic",
            "q": "scan.quarantine",
            "t": "tripwire.scan",
            "w": "tripwire.whitelist",
            "settings": "core.settings",
            "update": "core.update",
            "version": "core.version"
        }

        self.assertDictEqual(expected_optargs, self.malscan.settings.optargs)

    def test_config_file(self):
        self.assertEqual(
            self.base_path + '/config/malscan.conf',
            self.malscan.settings.settings_file
        )
        self.assertEqual('global', self.malscan.settings.settings_mode)
