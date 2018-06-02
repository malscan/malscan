import malscan
import io
import unittest

from setuptools import setup

install_requirements = []

test_requirements = [
    'coverage',
    'codecov'
] + install_requirements

with io.open('README.md', encoding='UTF-8') as reader:
    readme = reader.read()


def malscan_test_suite():
    test_loader = unittest.TestLoader()
    test_suite = test_loader.discover('tests', pattern='test_*.py')
    return test_suite


setup(
    name='Malscan',
    version=malscan.__version__,
    packages=['malscan'],
    url='https://github.com/malscan/malscan',
    license='MIT',
    author='Josh Grancell',
    author_email='jgrancell@malscan.com',
    description='Linux web server malware scanner',
    long_description=readme,
    install_requires=install_requirements,
    extras_require={},
    tests_require=test_requirements,
    test_suite='setup.malscan_test_suite',
    classifiers=[
        "Development Status :: 2 - Pre-Alpha",
        "Intended Audience :: System Administrators",
        "Programming Language :: Python",
        "Programming Language :: Python :: 3.6"
    ]

)
