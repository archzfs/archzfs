#!/usr/bin/env python
# encoding: utf-8
#
# ============================================================================
# package.py -- Intro
# ============================================================================
#
# This script builds arch packages in a clean chroot and places them into a
# pacman repository.
#
# :: NOTICE ::
#
# This script requires a specific directory structure and configuration file
# (config.json) in order to operate properly.
#
# ============================================================================
# Directory structure
# ============================================================================
#
# <repo_name>/
# |--archiso/
# |--|--i686/
# |--|--x86_64/
# |--devsrc/
# |--|--<package1>/
# |--|--|--PKGBUILD
# |--stage/
# |--|--<package-version>/
# |--|--|--{i686,x86_64,sources}/
# |--depends/
# |--|--<dependency1>
# |--|--|--<dependency1.pkg.tar.xz
# |--{community,core,extra,multilib}/
#
# [archiso]
#
# This is a special directory containing a repository to be compatible with the
# current archiso release. For example, the ZFS packages require a specific
# kernel version to function. When booting into the archiso to rescue a ZFS
# filesystem, it would then be necessary to install the ZFS kernel modules for
# the kernel contained in the archiso. As of Decemember 2012 this is kernel
# 3.6.8. This repository should track the current archiso release.
#
# [devsrc]
#
# These are the development sources to the packages of the repository. It is
# useful to have them in the same directory as the repository so that the
# entire repository can be versioned with a DVCS such as git.
#
# [community|core|extra|multilib]
#
# Arch linux has these repositories as default, and this script mimics them. So
# if you think your package should be part of the community repo, like most
# are, then it will be saved in the community directory as long as it is
# configured in the configuration file.
#
# [stage]
#
# When packages are built, the complied output is saved to the stage directory
# under the name of the package and version number. The reason for the stage is
# to allow the packager to first inspect the package and package signatures to
# determine correctness. Once correctness has been verified, the package.py can
# be used to add the packages to the repository. Once this is done, the
# packages in the stage directory are removed.

# [Hosting the project directory]
#
# This entire project directory can then be hosted on a webserver to allow
# users to add your signed repository to their pacman.conf using the following
# configuration:
#
# [<repo_name>]
# http://mycoolwebpage.com/$repo/$arch
#
# archiso users, the can use the following:
#
# [<repo_name>]
# http://mycoolwebpage.com/$repo/archiso/$arch
#


import argparse
import subprocess
import os
import re
import logging
import datetime
import sys
import glob
import json


# Setup logging
from logging import Formatter, getLogger, StreamHandler
logger = logging.getLogger(__name__)


# Set the logging level, possible values include DEBUG, INFO, WARNING, ERROR,
# and CRITICAL
# Prefix for logging output
PREFIX = '[>>>]'


# Dependency script for getting a list of dependencies the package depends on
# Many scripts use bash to determine the dependencies based on architectures,
# this script allows us to extract those dependencies.
BASH_DEP_SCRIPT = """arches=(i686 x86_64);
for march in "${arches[@]}"; do
    export CARCH="${march}";
    source PKGBUILD;
    echo "## ${march}-depends ##";
    for dep in "${depends[@]}"; do
        echo $dep;
    done
    echo "## ${march}-makedepends ##";
    for dep in "${makedepends[@]}"; do
        echo $dep;
    done
    echo "## ${march}-optdepends ##";
    for dep in "${optdepends[@]}"; do
        echo $dep;
    done
done
"""


# Documentation for ansi escape sequences.
# http://bluesock.org/~willg/dev/ansi.html#sequences
# http://en.wikipedia.org/wiki/ANSI_escape_code
# http://docs.python.org/reference/lexical_analysis.html
# `\033[` is the escape sequence character. `\033` is octal.
ATTR_CODES = {
    'bold': '1',
    'italic': '3',
    'strike': '9',
    'underline': '4',
    'erase': '\033[K',  # Clear to the end of the line
    'reset': '\033[0m',  # All attributes off
}


FG_COLOR_CODES = {
    'black': 30,
    'red': 31,
    'green': 32,
    'yellow': 33,
    'blue': 34,
    'magenta': 35,
    'cyan': 36,
    'white': 37,
    'default': 38,
}


BG_COLOR_CODES = {
    'bgred': 41,
    'bgblack': 40,
    'bggreen': 42,
    'bgyellow': 43,
    'bgblue': 44,
    'bgmagenta': 45,
    'bgcyan': 46,
    'bgwhite': 47,
    'bgdefault': 49,
    'bggrey': 100,
}


def ansi_builder(text, fgcolor, bgcolor, attr):
    """Wrap text in an ansi escape sequence, with bolding.

    :color: The color to wrap the text in.
    :text: The text to wrap.
    :attr: The attribute to wrap the text in.

    """
    fgcc = ''
    if fgcolor:
        assert(fgcolor in FG_COLOR_CODES)
        fgcc = str(FG_COLOR_CODES[fgcolor]) + ';'

    bgcc = ''
    if bgcolor:
        assert(bgcolor in BG_COLOR_CODES)
        bgcc = str(BG_COLOR_CODES[bgcolor]) + ';'

    attrc = ''
    if attr:
        assert(attr in ATTR_CODES)
        attrc = ATTR_CODES[attr] + ';'

    ccds = attrc + fgcc + bgcc
    # print('033[{}m{}{}'.format(ccds[:-1], text, ATTR_CODES['reset'][1:]))

    return '\033[{}m{}{}'.format(ccds[:-1], text, ATTR_CODES['reset'])


OUTPUT_PREFIX = ansi_builder(PREFIX, 'cyan', '', 'bold') + ': '


class _ANSIFormatter(Formatter):
    """Convert a `logging.LogReport' object into colored text, using ANSI
    escape sequences.

    """
    def format(self, record):
        mtype = ''
        if record.levelname is 'INFO':
            mtype = ansi_builder(record.levelname + ' ', 'cyan', '', 'bold')
        elif record.levelname is 'WARNING':
            mtype = ansi_builder(record.levelname, 'yellow', '', 'bold')
        elif record.levelname is 'ERROR':
            mtype = ansi_builder(record.levelname, 'red', '', 'bold')
        elif record.levelname is 'CRITICAL':
            mtype = ansi_builder(record.levelname, '', 'bgred', 'bold')
        elif record.levelname is 'DEBUG':
            mtype = ansi_builder(record.levelname, '', 'bggrey', 'bold')
        else:
            mtype = ansi_builder(record.levelname, 'white', '', 'bold')
        # tdate = get_time_string()
        # return OUTPUT_PREFIX + mtype + ': ' + tdate + ': ' + record.msg
        return OUTPUT_PREFIX + mtype + ': ' + record.msg


def init_logging(level, logger=getLogger(), handler=StreamHandler()):
    """Initializes the logger.

    """
    fmt = _ANSIFormatter()
    handler.setFormatter(fmt)
    logger.addHandler(handler)
    if not level:
        level = logging.WARN
    logger.setLevel(level)


def get_time_string():
    """Returns a formatted time string.

    :returns: A formatted time string.

    """
    now = datetime.datetime.now()
    return now.strftime('%a %b %d %H:%M:%S %Y')


def _logger(text, text_attr='', note='', note_attr='', note_fgcolor='',
            note_bgcolor='', date=True, prefix=True):
    """Prints to stdout.

    _logger is responsible for making pretty output and is used throughout the
    entire program. Any whitepsace characters at the start or ends of the line
    are preserved. So lines containing '\r' will overlap. This is useful for
    progress bars and such.

    :text: The text to output.
    :text_attr: ANSI attribute to wrap text with.
    :note: String to append to the text.
    :note_attr: ANSI attribute to wrap note with.
    :note_fgcolor: Color of the appended note.
    :note_bgcolor: Background color of the note.
    :date: If true, the date will be appended.
    :prefix: If true, the date and OUTPUT_PREFIX will be displayed.

    """
    prefix = OUTPUT_PREFIX
    if date:
        prefix = prefix + get_time_string() + ': '
    if note:
        note = ansi_builder(note, note_fgcolor, note_bgcolor, note_attr) + ' '
    pad_re = re.match(r'(\s*).*(\s*)', text)
    if pad_re:
        pre_pad = pad_re.group(1)
        pos_pad = pad_re.group(2)
    end = '\r' if text[-1] == '\r' else '\n'
    stext = text.strip()
    if text_attr:
        stext = ansi_builder(stext, '', '', text_attr)
    output = ''.join((pre_pad, prefix, note, stext, pos_pad,
                      ATTR_CODES['reset'], end))
    sys.stdout.write(output)


def log_begin(text):
    """Logs output with [Begin] appended to the start of the string.

    :text: The message to write to stdout.

    """
    _logger(text, '', '[Begin]', 'bold', 'white', 'bgcyan')


def log_done(text):
    """Logs output with [Done] appended to the start of the string.

    :text: The message to write to stdout.

    """
    _logger(text, '', '[FINISHED]', 'bold', 'white', 'bgcyan')


def log_noprefix(text):
    """Logs output without the prefix.

    :text: The message to write to stdout.

    """
    _logger(text, date=False, prefix=False)


def log_note(text, note, fgcolor, bgcolor):
    """Logs output without the prefix.

    :text: The message to write to stdout.

    """
    assert(fgcolor in FG_COLOR_CODES)
    assert(bgcolor in BG_COLOR_CODES)
    _logger(text, '', note, 'bold', fgcolor, bgcolor)


def log(text):
    """Prints to stdout with timestap and OUTPUT_PREFIX.

    :text: The message to write to stdout.

    """
    _logger(text, date=False, prefix=True)


def set_new_sums(package_path):
    """Get new sums and change in the PKGBUILD

    :package_path: The path to the PKGBUILD for the package.

    """
    orig_dir = os.getcwd()
    os.chdir(package_path)
    logger.debug('Changed dir: ' + package_path)
    pkg = os.path.basename(package_path)
    proc = subprocess.Popen(['makepkg', '-c', '-g'], stdout=subprocess.PIPE,
                            stderr=subprocess.PIPE)
    sout, serr = proc.communicate()
    smsum = re.findall(r'\ *(?:sha|md)\d+sums=\([\w\s\n\']+\)',
                       sout.decode('UTF-8'))
    if len(smsum) > 1:
        logger.warning('RE pattern returned more than one occurrence!')

    with open('PKGBUILD', 'r') as p_file:
        pkg_conf = p_file.read()

    pfsum = re.findall(r'\ *(?:sha|md)\d+sums=\([\w\s\n\']+\)', pkg_conf)
    if pfsum and pfsum[0] != smsum[0]:
        log_noprefix('Generating hashes for ' + pkg)
        new_pconf = pkg_conf.replace(pfsum[0], smsum[0])
        log_noprefix('Writing updated PKGBULID')
        with open('PKGBUILD', 'w') as p_file:
            p_file.write(new_pconf)
    else:
        log_noprefix('Hashes up-to-date for ' + pkg)
    os.chdir(orig_dir)
    logger.debug('Changed dir: ' + orig_dir)


def get_pkgbuild_version(package_path):
    """Get the version number for package from the PKGBUILD.

    :package_path: The path containing the PKGBUILD.
    :returns: The version of the package contained in the PKGBUILD.

    """
    with open(os.path.join(package_path, 'PKGBUILD'), 'r') as p_file:
        pkgb = p_file.read()
    # TODO: Sat Jan 12 08:35:48 PST 2013: Merge these two regexs
    pkgver = re.findall(r'pkgver=([\d\w.]+)\n', pkgb)
    pkgrel = re.findall(r'pkgrel=(\d+)\n', pkgb)
    return pkgver[0] + '-' + pkgrel[0] or ''


def exec_dependency_getter():
    """Creates a temporary script to source the PKGBUILD for package to
    retrieve its dependencies.

    Returns a string of the script output.

    :returns: A string of the script output that includes all dependencies for
              both i686 and x86_64 packages.

    """
    with open('dep_getter.sh', 'w') as b_file:
        b_file.write(BASH_DEP_SCRIPT)
    cmd = ['chmod', '755', 'dep_getter.sh']
    logger.debug(" ".join(cmd))
    proc = subprocess.call(cmd)
    if proc > 0:
        logger.error('Error: could not set permissions on dep_getter.sh')
        sys.exit(1)
    proc = subprocess.Popen(['bash', 'dep_getter.sh'], stdout=subprocess.PIPE)
    sout = proc.communicate()[0].decode()
    if proc.returncode > 0:
        logger.error('Error: could not execute dep_getter.sh')
        sys.exit(1)
    os.remove('dep_getter.sh')
    return sout


aname = ansi_builder('package.py -- Magically build and add packages to an '
                     'Arch Linux package repository.', 'yellow', 'bgcyan',
                     'bold')

intro = '\n' + aname

usage = intro + """

    [[NOTE]]

    package.py builds packages in a chroot environment. See the package.py
    source code.

Usage: package.py [OPTIONS]

Commands:

build   Build the selected packages and sources. ALL packages by default.

source  Build the source of the package. This does not need to be specified if
        using the 'build' command.

repo    Add selected packages to the projects repositories.

Optional arguments for all commands:
-h, --help          Show this help message and exit.
-p PKG, -p N        Select packages to use.

Optional arguments for the 'build' command:
-r  Select chroot root path. Example "/opt/chroot".
-l  Select chroot copy name. Example "anet".
-c  Clean chroot before building.

Optional arguments for the 'source' command:
NONE

Optional arguments for the 'repo' command:
NONE"""


# Script globals
class App:
    """The application storage object.

    """
    def __init__(self):
        self.args = None
        # Tracks properties of each package being processed
        self.packages = {}  # Set in load_configuration
        self.signing_key = ''
        self.log_level = ''
        self.chroot_path = ''
        self.chroot_copy = ''
        self.repo_path = ''
        self.base_path = os.getcwd()

        # Load script configuration
        self.argparser()
        self.load_configuration()
        init_logging(level=self.log_level)

        # Display a message
        log_note('Welcome!', 'package.py', 'white', 'bgred')
        logger.debug(str(self.args))
        logger.debug('Signing Key: ' + self.signing_key)
        logger.debug('Package Object: ' + str(self.packages))
        logger.debug('LOG_LEVEL: ' + self.log_level)

        # Lanch the subcommand
        if self.args.subparser_name == 'build':
            self.check_for_built_packages()
            if self.args.c:
                self.chroot_clean()
            self.build()
        elif self.args.subparser_name == 'source':
            self.source()
        elif self.args.subparser_name == 'repo':
            self.repo()

    def load_configuration(self):
        """Loads the json configuration in the same directory.

        """
        with open(os.path.join(self.base_path, 'config.json'), 'r') as p_file:
            conf = p_file.read()
        jobj = json.loads(conf)[0]
        self.signing_key = jobj['SigningKey']
        for pkg in jobj['PackageBuildOrder']:
            self.packages[pkg] = {'filename': '', 'version': '', 'path': '',
                                  'dest': {'x86_64': '', 'i686': ''},
                                  'deps': {'x86_64': [], 'i686': []},
                                  'overwrite': True}
        self.log_level = jobj['LogLevel']
        self.chroot_path = jobj['ChrootPath']
        self.chroot_copy = jobj['ChrootCopy']
        self.repo_path = jobj['RepoPath']

    def argparser(self):
        """Parses the script arguments with argparse.

        """
        # Parse the arguments!
        parser = argparse.ArgumentParser(add_help=False)
        parser.add_argument('-h', '--help', action='store_true', default=False)
        parser.add_argument('-p', action='append', metavar='pkg')
        subparser = parser.add_subparsers(dest='subparser_name')

        build_parser = subparser.add_parser('build')
        build_parser.add_argument('-r', nargs='?')
        build_parser.add_argument('-l', nargs='?')
        build_parser.add_argument('-c', action='store_true', default=False)

        subparser.add_parser('repo')

        subparser.add_parser('source')

        self.args = parser.parse_args()

        if len(sys.argv) == 1 or self.args.help:
            print(usage)
            sys.exit(1)

    def chroot_clean(self):
        """Creates a clean chroot.

        """
        for arch in ('x86_64', 'i686'):
            suffix = '32' if arch == 'i686' else '64'
            cdir = os.path.join(self.chroot_path, arch)
            copydir = os.path.join(cdir, self.chroot_copy + suffix)
            log('Creating ' + copydir)
            proc = subprocess.call(['sudo', 'mkdir', '-p', copydir])
            if proc > 0:
                logger.warning('Error: could not create directory')
            log_noprefix('Creating clean chroot at ' + copydir)
            proc = subprocess.call(['sudo', 'rsync', '-a', '--delete', '-q',
                                    '-W', '-x', cdir + '/root/', copydir])
            if proc > 0:
                logger.critcal('Error: could not create clean chroot!')
                sys.exit(1)

    def chroot_install_local_dependencies(self, package, arch):
        """Install pre-built packages from the stage or depends.

        :package: The name of the package.
        :arch: The architecture being targeted.

        """
        log('Getting dependency list for ' + package)
        deps = self.get_depends_list(package)[arch]
        i_pkg_list = []
        for pkg in deps:
            if '=' in pkg:
                pkgname, pkgvers = pkg.split('=')
            else:
                pkgname = pkg
                pkgvers = ''
            # First search the stage directory
            pkg_name_temp = '{1}-{2}*.pkg.tar.xz'
            pkg_full_path = os.path.join(self.base_path, 'stage', '*', '{0}',
                                         pkg_name_temp)
            bpath = pkg_full_path.format(arch, pkgname, pkgvers)
            logger.debug('Dep stage check path: ' + bpath)
            bpkg = glob.glob(bpath)

            # If there were no packages found in the stage directory, search
            # the 'depends' directory.
            if bpkg:
                i_pkg_list.extend(bpkg)
            else:
                dpath = os.path.join(self.base_path, 'depends', pkg,
                                     os.path.basename(pkg_full_path))
                dpath = dpath.format(arch, pkgname, pkgvers)
                logger.debug('Local dependency check: ' + dpath)
                dpkg = glob.glob(dpath)
                if dpkg:
                    i_pkg_list.extend(dpkg)

        if i_pkg_list:
            logger.debug('Dependencies to install: ' + str(i_pkg_list))
            self.chroot_install_packages(i_pkg_list, arch)

    def chroot_install_packages(self, packages, arch):
        """Installs the packages passed as arguments into the chroot.

        :packages: The list of packages to install.
        :arch: The architecture being targeted.

        """
        for pkg in packages:
            suffix = '32' if arch == 'i686' else '64'
            cdir = os.path.join(self.chroot_path, arch)
            copydir = os.path.join(cdir, self.chroot_copy + suffix)
            pbname = os.path.basename(pkg)

            log_noprefix('Checking signature for ' + pkg)
            cmd = ['sudo', 'pacman-key', '-v', pkg + '.sig']
            logger.debug(" ".join(cmd))
            proc = subprocess.call(cmd)
            if proc > 0:
                logger.critical('Signature check failed!')
                sys.exit(1)

            log_noprefix('Copying ' + pkg + ' to the chroot')
            cmd = ['sudo', 'cp', pkg, os.path.join(copydir, pbname)]
            logger.debug(" ".join(cmd))
            proc = subprocess.call(cmd)
            if proc > 0:
                logger.critical('Could not copy the package!')
                sys.exit(1)

            log_noprefix('Installing ' + pkg)
            pac_cmd = 'pacman -U /' + pbname + ' --noconfirm'
            cmd = 'sudo setarch {} mkarchroot -r "{}" {}'.format(arch, pac_cmd,
                                                                 copydir)
            logger.debug(cmd)
            proc = subprocess.call(cmd, shell=True)
            if proc > 0:
                logger.warning('There was a problem installing the package!')

            cmd = ['sudo', 'rm', os.path.join(copydir, pbname)]
            logger.debug(" ".join(cmd))
            proc = subprocess.call(cmd)
            if proc > 0:
                logger.warning('There was a problem removing the package!')

    def get_depends_list(self, package):
        """The return value is a dictionary with dependency lists for i686 and
        x86_64.

        :package: The name of the package.
        :returns: A dictionary of dependencies.

        """
        if self.packages[package]['deps']['i686']:
            return self.packages[package]['deps']
        package_path = self.packages[package]['path']
        orig_dir = os.getcwd()
        os.chdir(package_path)
        logger.debug('Changed dir: ' + package_path)
        dep_str = exec_dependency_getter()
        x32re = re.compile(r'## i686-[\w]+ ##\n([\w\.<>=\n-]+)\n')
        x64re = re.compile(r'## x86_64-[\w]+ ##\n([\w\.<>=\n-]+)\n')
        temp_list = {}
        temp_list['i686'] = x32re.findall(dep_str)
        temp_list['x86_64'] = x64re.findall(dep_str)
        for arch in ('x86_64', 'i686'):
            for dep in temp_list[arch]:
                self.packages[package]['deps'][arch].extend(dep.split('\n'))
        os.chdir(orig_dir)
        logger.debug('Changed dir: ' + orig_dir)
        return self.packages[package]['deps']

    def check_for_built_packages(self):
        """Check if package has been built and is stored in the stage
        directory.

        """
        for arch in ('x86_64', 'i686'):
            for pkg in self.packages:
                if self.args.p and pkg not in self.args.p:
                    continue
                package_path = os.path.join(self.base_path, 'devsrc', pkg)
                self.packages[pkg]['path'] = package_path
                pkg_ver = get_pkgbuild_version(package_path)
                self.packages[pkg]['version'] = pkg_ver
                pkg_file_name = '{}-{}-{}.pkg.tar.xz'.format(pkg, pkg_ver,
                                                             arch)
                self.packages[pkg]['filename'] = pkg_file_name
                pkg_full_path = os.path.join(self.base_path, 'stage', pkg + '-'
                                             + pkg_ver, arch, pkg_file_name)
                self.packages[pkg]['dest'][arch] = pkg_full_path
                if not os.path.exists(pkg_full_path):
                    log(pkg_full_path + ' does not exist')
                else:
                    mtmp = '{}{} for {} already exists. Overwrite? [Y/n] '
                    var = input(mtmp.format(OUTPUT_PREFIX, pkg, arch))
                    if var.lower() == 'y' or var == '':
                        logger.debug('Answered yes to overwrite')
                        self.packages[pkg]['overwrite'] = True
                    else:
                        logger.debug('Answered no to overwrite')
                        log('Keeping ' + pkg_full_path)
                        self.packages[pkg]['overwrite'] = False

    def move_package_to_stage(self, package, arch):
        """Moves a newly built package to stage/.

        :package: The name of the package to move.
        :arch: The architecture to target.

        """
        package_path = self.packages[package]['path']

        # Get the version of the built package from the filename and move
        # the package to the testing directory.
        try:
            pkg = glob.glob(os.path.join(package_path, '*-' + arch +
                                         '.pkg.tar.xz'))[0]
        except IndexError:
            pass

        if not pkg:
            logger.warning('Could not find package in ' + package_path)
            return

        bdest = os.path.dirname(self.packages[package]['dest'][arch])
        mkcmd = 'mkdir -p ' + bdest
        logger.info(mkcmd)
        proc = subprocess.call(mkcmd, shell=True)
        if proc > 1:
            logger.warning('Error: could not create stage directories')

        # Move the package binary and signature
        log('Moving {} to {}'.format(pkg, bdest))
        mvcmd = 'mv {}* {}'.format(pkg, bdest)
        logger.info(mvcmd)
        proc = subprocess.call(mvcmd, shell=True)
        if proc > 1:
            logger.warning('Error: could not move the package to stage')

    def move_source_to_stage(self, package):
        """Moves a newly built package source to stage/.

        :package: The package name.
        :arch: The architecture to target.

        """
        package_path = self.packages[package]['path']
        try:
            source = glob.glob(os.path.join(package_path, '*.src.tar.gz'))[0]
        except IndexError:
            pass
        if not source:
            logger.warning('Could not find package source')
            return
        logger.debug('Source glob: ' + str(source))
        dname = os.path.dirname(self.packages[package]['dest']['i686'])
        sdest = os.path.normpath(os.path.join(dname, '..', 'source'))
        mkcmd = 'mkdir -p ' + sdest
        logger.info(mkcmd)
        proc = subprocess.call(mkcmd, shell=True)
        if proc > 1:
            logger.warning('Error: could not create stage source '
                           'directories')
        log('Moving ' + source + ' to stage')
        mvcmd = 'mv {} {}'.format(source, sdest)
        logger.info(mvcmd)
        proc = subprocess.call(mvcmd, shell=True, stderr=subprocess.DEVNULL)
        if proc > 1:
            logger.warning('Error: could not move package source')

    def gpg_sign_packages(self):
        """Signs all built packages.

        """
        for arch in ('x86_64', 'i686'):
            for pkg, obj in self.packages.items():
                orig_dir = os.getcwd()
                fname = os.path.basename(obj['dest'][arch])
                dpath = os.path.dirname(obj['dest'][arch])
                if not dpath:
                    logger.debug('Not signing: ' + pkg)
                    continue
                os.chdir(dpath)
                logger.debug('Changed dir: ' + dpath)
                cmd = ['gpg', '--detach-sign', '-u', self.signing_key,
                       '--use-agent', fname]
                logger.debug(" ".join(cmd))
                proc = subprocess.call(cmd)
                if proc > 0:
                    logger.warning('There was a problem signing ' + pkg)
                os.chdir(orig_dir)
                logger.debug('Changed dir: ' + orig_dir)

    def build(self):
        """Builds the packages in the devsrc directory.

        """
        for arch in ('x86_64', 'i686'):
            for pkg in self.packages:
                if self.args.p and pkg not in self.args.p:
                    continue
                self.build_package(pkg, arch)
        self.gpg_sign_packages()

    def build_package(self, package, arch):
        """Build a package for the targeted architecture.

        :package: The package to build.
        :arch: The architecture to target.

        """
        if (self.args.p and not package in self.args.p):
            return

        log('\nProcessing "{}" for {}'.format(package, arch))

        pkg_full_path = self.packages[package]['path']
        overwrite = self.packages[package]['overwrite']

        # Make sure the hashes are up-to-date
        if overwrite:
            set_new_sums(pkg_full_path)

            # Clear the build directory in the chroot
            suffix = '32' if arch == 'i686' else '64'
            cdir = os.path.join(self.chroot_path, arch)
            copydir = self.chroot_copy + suffix
            rmcmd = 'sudo rm -rf ' + os.path.join(cdir, copydir + '/build/*')
            logger.info(rmcmd)
            subprocess.call(rmcmd, shell=True)

            # Install any local dependencies for the package, these can be
            # stored in the stage/ or depends/ directories in the project root.
            self.chroot_install_local_dependencies(package, arch)

            orig_dir = os.getcwd()
            os.chdir(pkg_full_path)
            logger.debug('Changed dir: ' + pkg_full_path)
            # Build the package in the chroot
            log('Building "{}" in "{}"'.format(package, copydir))
            cmd = ('sudo setarch {} makechrootpkg -u -r {} -l {} '
                   '-- -i'.format(arch, cdir, copydir))
            logger.info(cmd)
            proc = subprocess.call(cmd, shell=True)
            os.chdir(orig_dir)
            logger.debug('Changed dir: ' + orig_dir)
            if proc > 0:
                logger.critical('Error: could not build in the chroot!')
                sys.exit(1)

        # Move the pacman package source. We only do this if arch is i686 since
        # there can be only one.
        if arch == 'i686':
            self.build_source_package(package)

        # Move package to stage directory
        self.move_package_to_stage(package, arch)

        # Cleanup
        rmcmd = 'rm -r ' + pkg_full_path + '/*.log src/ 2> /dev/null'
        logger.info(rmcmd)
        proc = subprocess.call(rmcmd, shell=True)
        if proc > 1:
            logger.warning('There was a problem cleaning the working files')

    def source(self):
        """Builds the source to the packages in the devsrc directory.

        """
        for pkg in self.packages:
            if self.args.p and pkg not in self.args.p:
                continue
            self.build_source_package(pkg)

    def build_source_package(self, package):
        """Build package source for package.

        :package: The package to build.
        :arch: The architecture to target.

        """
        log('Creating source package for ' + package)
        pkg_full_path = os.path.join(self.base_path, 'devsrc', package)
        orig_dir = os.getcwd()
        os.chdir(pkg_full_path)
        logger.debug('Changed dir: ' + pkg_full_path)
        cmd = ['makepkg', '-c', '-S', '-f']
        logger.info(" ".join(cmd))
        proc = subprocess.call(cmd)
        os.chdir(orig_dir)
        logger.debug('Changed dir: ' + orig_dir)
        if proc > 0:
            logger.warning('Error: Could not build source package')
        self.move_source_to_stage(package)

    def add_package_to_repo(self, package, arch):
        """Adds a package to a repository set in the config.

        :package: The package to add.
        :arch: The architecture to target.

        """
        # Delete the old packages
        repo = self.repo_path
        old_pkgs = glob.glob(os.path.join(repo, arch, package + '*'))
        for pkg in old_pkgs:
            log('Deleting old repo package ' + pkg)
            try:
                os.remove(pkg)
            except:
                logger.warning('Error: could not remove package')

        # Copy the packages in stage to to the repo
        ppath = os.path.join(self.base_path, 'stage', package)
        log('Copying "{}" to "{}"'.format(package, repo))
        cp_pat = 'cp {0}*/{1}/* {2}/{1}/'
        cp_cmd = cp_pat.format(ppath, arch, repo)
        logger.info(cp_cmd)
        proc = subprocess.call(cp_cmd, shell=True)
        if proc > 1:
            logger.warning('Error: could not move the package to the repo')

        # Copy the package source in stage to the repo directory
        ppath = os.path.join(self.base_path, 'stage', package)
        os.mkdir(os.path.join(repo, 'sources'))
        cp_pat = 'cp {0}*/source/* {1}/sources/'
        cp_cmd = cp_pat.format(ppath, repo)
        logger.info(cp_cmd)
        proc = subprocess.call(cp_cmd, shell=True)
        if proc > 1:
            logger.warning('Error: could not move the package to the repo')

        # Add the new packages to the repo
        repo_name = os.path.basename(os.getcwd())
        orig_dir = os.getcwd()
        os.chdir(os.path.join(repo, arch))
        logger.debug('Changed dir: ' + os.getcwd())
        pkg = glob.glob(package + '*.pkg.tar.xz')[0]
        log('Adding "{}" to the "{}" {} repository.'.format(pkg, repo_name,
                                                            arch))
        repo_cmd = ['repo-add', '-s', '-v', '-k', self.signing_key, repo_name +
                    '.db.tar.xz', pkg]
        logger.info(" ".join(repo_cmd))
        proc = subprocess.call(repo_cmd)
        if proc > 0:
            logger.warning('Error: could not add the package to the repo')
        os.chdir(orig_dir)
        logger.debug('Changed dir: ' + orig_dir)

    def repo(self):
        """Repo subcommand function. Adds built packages to a repository.

        """
        for arch in ('x86_64', 'i686'):
            for pkg in self.packages:
                if self.args.p and pkg not in self.args.p:
                    continue
                self.add_package_to_repo(pkg, arch)


if __name__ == '__main__':
    try:
        App()
        log('All done')
    except (KeyboardInterrupt, EOFError):
        log('\nToodles')
