# -*- encoding: utf-8 -*-
# pylint: skip-file
import sys
import unittest
from malscan.help import Help
from malscan import __version__
if sys.version_info >= (3, 0):
    from io import StringIO
else:
    from StringIO import StringIO


class TestHelp(unittest.TestCase):
    def setUp(self):
        self.help = Help()
        self.maxDiff = None

    def test_parameters(self):
        self.assertEqual(self.help.style['header'], '\033[95m')
        self.assertEqual(self.help.style['info'], '\033[94m')
        self.assertEqual(self.help.style['success'], '\033[92m')
        self.assertEqual(self.help.style['warning'], '\033[93m')
        self.assertEqual(self.help.style['error'], '\033[91m')
        self.assertEqual(self.help.style['normal'], '\033[0m')
        self.assertEqual(self.help.style['bold'], '\033[1m')
        self.assertEqual(self.help.style['underline'], '\033[4m')
        self.assertEqual(self.help.style['newline'], '\n')

    def test_version(self):
        capturedOutput = StringIO()
        sys.stdout = capturedOutput

        self.help.version()
        sys.stdout = sys.__stdout__

        self.assertEqual(__version__ + "\n", capturedOutput.getvalue())

    def test_display(self):
        capturedOutput = StringIO()
        sys.stdout = capturedOutput

        self.help.display("last tuesday")
        sys.stdout = sys.__stdout__
        self.assertEqual(
            "{}, last updated: last tuesday\n\n"
            "\033[95mUsage:\033[0m\n"
            "    malscan [parameters] [target]\n\n"
            "\033[95mScan Modes:\033[0m\n"
            "    -l         suspicious string scanning mode\n"
            "    -m         file extension match scanning mode\n"
            "    -s         basic malware scan\n"
            "    -q         malware quarantine mode\n\n"
            "\033[95mTripwire:\033[0m\n"
            "    -t         scans target directory"
            " for altered whitelisted files\n"
            "    -w         whitelists all files in the "
            "target directory\n\n"
            "\033[95mGeneral Commands:\033[0m\n"
            "    config     displays running malscan configuration\n"
            "    update     updates malscan malware signatures\n"
            "    version    shows application"
            " and signature versions\n".format(__version__),
            capturedOutput.getvalue()
        )
