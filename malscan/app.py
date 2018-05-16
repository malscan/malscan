# -*- encoding: utf-8 -*-
""" App entry point. """
from malscan.configuration import Configuration
from malscan.help import Help

from sys import argv as Argv
from os import path, getcwd


class Malscan():
    """ Malscan is an app object that allows us
    to run various malscan commands """

    def __init__(self):
        self.config = Configuration()
        self.config.load()

        self.arguments = Argv
        self.argument_count = len(self.arguments)
        self.help = Help()

    def load(self):
        # Making sure that we've received the appropriate number of arguments
        if self.argument_count == 1:
            self.help.display(self.config.get('last_database_update'))
        else:
            # Removing the self-referencing argument
            del self.arguments[0]

            if "update" in self.arguments:
                # This is not yet implemented
                import malscan.core.update as Updater
                Updater.run()
            elif "version" in self.arguments:
                self.help.version()
            elif "config" in self.arguments:
                self.config.show()
            else:
                self._run_scanner()

    def _run_scanner(self):
        """ Configures the scanning instance and invokes the scanner """
        self.targets = []
        self.scan_modes = []
        for arg in self.arguments:
            if arg.startswith("-"):
                for opt in arg:
                    if opt in self.config.show_optargs():
                        self.scan_modes.append(self.config['optargs'][opt])
            else:
                self._add_target(arg)
        if self.targets == []:
            self._add_target(getcwd())
        print('We are going to be running scans on:')
        print('    ' + '\n    '.join(self.targets))
        print('Scan types:')
        print('    ' + '\n    '.join(self.scan_modes))

    def _check_target(target):
        """ Determines if a string is a valid target for scanning """
        if path.isfile(target) or path.isdir(target):
            return True
        else:
            return False

    def _add_target(self, target):
        """ Adds a target to the target list, if it is a valid target """
        if self._check_target(target):
            self.targets.append(target)
