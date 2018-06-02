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

    def test_configuration(self):

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
        config = self.malscan.config.configuration
        self.assertDictEqual(expected, config)

    def test_optargs(self):
        expected_optargs = {
            "l": "scan.string",
            "m": "scan.mime",
            "s": "scan.basic",
            "q": "scan.quarantine",
            "t": "tripwire.scan",
            "w": "tripwire.whitelist",
            "config": "core.config",
            "update": "core.update",
            "version": "core.version"
        }

        self.assertDictEqual(expected_optargs, self.malscan.config.optargs)

    def test_config_file(self):
        self.assertEqual(
            self.base_path + '/config/malscan.conf',
            self.malscan.config.configuration_file
        )
        self.assertEqual('global', self.malscan.config.configuration_mode)
