# -*- encoding: utf-8 -*-
# pylint: skip-file
import sys
import unittest
import os
from malscan.help import Help
from malscan.error import Error
if sys.version_info >= (3, 0):
    from io import StringIO
else:
    from StringIO import StringIO


class TestHelp(unittest.TestCase):
    def setUp(self):
        self.exception = Error()
        self.help = Help()
        self.maxDiff = None
        if os.path.isfile(self.exception.log_file):
            os.remove(self.exception.log_file)

    def test_init(self):
        self.assertIsInstance(self.exception.help, Help)
        self.assertIsInstance(self.exception, Error)
        self.assertTrue(os.path.isdir(self.exception.log_path))
        self.assertFalse(os.path.isfile(self.exception.log_file))
        self.assertTrue(os.access(self.exception.log_path, os.W_OK))

    def test_log_writer(self):
        file = open(self.exception.log_file, 'a+')
        self.assertEqual("", file.read())
        self.exception._log_writer('This is a testing string.')
        self.assertEqual("This is a testing string.\n", file.read())
        file.close()
        os.remove(self.exception.log_file)

    def test_handle_exception(self):
        # Verifying that the log file is empty
        file = open(self.exception.log_file, 'a+')
        self.assertEqual("", file.read())

        # Catching print() for testing
        capturedOutput = StringIO()
        sys.stdout = capturedOutput

        # Throwing our exception and then resetting stdout
        self.exception._handle_exception(
            'This is a console test',
            'This is the log string test'
        )
        sys.stdout = sys.__stdout__

        # Verifying the console output
        self.assertEqual(
            "This is a console test\n",
            capturedOutput.getvalue()
        )

        # Verifying the log file output
        self.assertEqual("This is the log string test\n", file.read())
        file.close()
        os.remove(self.exception.log_file)

    def test_warning(self):
        # Verifying that the log file is empty
        file = open(self.exception.log_file, 'a+')
        self.assertEqual("", file.read())

        # Catching print() for testing
        capturedOutput = StringIO()
        sys.stdout = capturedOutput

        # Throwing our exception and then resetting stdout
        self.exception.warning(
            'This is a warning exception test.',
            'This is secondary.'
        )
        sys.stdout = sys.__stdout__

        # Verifying the console output
        self.assertEqual(
            "\033[93mThis is a warning exception test.\033[0m\n"
            "\033[93mThis is secondary.\033[0m\n",
            capturedOutput.getvalue()
        )

        # Verifying the log file output
        self.assertEqual(
            "WARNING: This is a warning exception test.\n",
            file.read())
        file.close()
        os.remove(self.exception.log_file)

        # Rerunning everything with no secondary
        file = open(self.exception.log_file, 'a+')
        self.assertEqual("", file.read())

        # Catching print() for testing
        capturedOutput = StringIO()
        sys.stdout = capturedOutput

        # Throwing our exception and then resetting stdout
        self.exception.warning(
            'This is a warning exception test.',
        )
        sys.stdout = sys.__stdout__

        # Verifying the console output
        self.assertEqual(
            "\033[93mThis is a warning exception test.\033[0m\n",
            capturedOutput.getvalue()
        )

        # Verifying the log file output
        self.assertEqual(
            "WARNING: This is a warning exception test.\n",
            file.read())
        file.close()
        os.remove(self.exception.log_file)

    def test_error(self):
        # Verifying that the log file is empty
        file = open(self.exception.log_file, 'a+')
        self.assertEqual("", file.read())

        # Catching print() for testing
        capturedOutput = StringIO()
        sys.stdout = capturedOutput

        # Throwing our exception and then resetting stdout
        self.exception.error(
            'This is an error exception test.',
            'This is the second line.')
        sys.stdout = sys.__stdout__

        # Verifying the console output
        self.assertEqual(
            (
                "\033[91mThis is an error exception test.\033[0m\n"
                "\033[91mThis is the second line.\033[0m\n"
            ),
            capturedOutput.getvalue()
        )

        # Verifying the log file output
        self.assertEqual(
            "ERROR: This is an error exception test.\n",
            file.read()
        )
        file.close()
        os.remove(self.exception.log_file)

        # Running the test without secondary
        file = open(self.exception.log_file, 'a+')
        self.assertEqual("", file.read())

        # Catching print() for testing
        capturedOutput = StringIO()
        sys.stdout = capturedOutput

        # Throwing our exception and then resetting stdout
        self.exception.error(
            'This is an error exception test.'
        )
        sys.stdout = sys.__stdout__

        # Verifying the console output
        self.assertEqual(
            (
                "\033[91mThis is an error exception test.\033[0m\n"
            ),
            capturedOutput.getvalue()
        )

        # Verifying the log file output
        self.assertEqual(
            "ERROR: This is an error exception test.\n",
            file.read()
        )
        file.close()
        os.remove(self.exception.log_file)

    def test_format_string(self):
        self.assertEqual(
            "\033[91mTest format string.\033[0m",
            self.exception._format_string('error', 'Test format string.')
        )

        self.assertEqual(
            "\033[93mTest format string.\033[0m",
            self.exception._format_string('warning', 'Test format string.')
        )

        self.assertEqual(
            "\033[92mTest format string.\033[0m",
            self.exception._format_string('success', 'Test format string.')
        )

        self.assertEqual(
            "\033[94mTest format string.\033[0m",
            self.exception._format_string('info', 'Test format string.')
        )
