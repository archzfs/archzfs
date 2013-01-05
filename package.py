#!/usr/bin/env python
# encoding: utf-8
#
# TODO: Fix recursive dependencies
#       If trying to build the zfs package, spl will be installed, but spl
#       can't be installed without spl-utils.
#
# TODO: Change testing directory layout.
#       It should be testing/{i686,x86_64,sources}.
#
import argparse
import subprocess
import os
import re
import logging
import datetime
import sys
import glob

PACKAGES = ['spl-utils', 'spl', 'zfs-utils', 'zfs']

# This is where the latest testing kernel can be found:
# http://mirrors.kernel.org/archlinux/testing/os/x86_64/

# Create the default clean chroot
# mkdir -p "/opt/chroot/i686"
# sudo setarch i686 mkarchroot -C /usr/share/devtools/pacman-extra.conf -M
# /usr/share/devtools/makepkg-i686.conf /opt/chroot/extra-i686/root base
# base-devel gnupg sudo

SIGNING_KEY = '0EE7A126'

# Prefix for logging output
PREFIX = '[>>>]'

from logging import Formatter, getLogger, StreamHandler, DEBUG

# This function uses ansi escape sequences.
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
        tdate = get_time_string()
        return OUTPUT_PREFIX + mtype + ': ' + tdate + ': ' + record.msg


def init_logging(level, logger=getLogger(), handler=StreamHandler()):
    logger = logging.getLogger()
    fmt = _ANSIFormatter()
    handler.setFormatter(fmt)
    logger.addHandler(handler)
    if not level:
        level = logging.WARN
    logger.setLevel(level)

init_logging(level=DEBUG)
logger = logging.getLogger(__name__)

if not PACKAGES:
    logger.critical('Did not find packages in the "devsrc" directory')
    sys.exit(1)


def get_time_string():
    """Returns a formatted time string.

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
    _logger(text, date=True, prefix=True)


parser = argparse.ArgumentParser(description='Magically add packages to a '
                                 'repository.')

parser.add_argument('-r', nargs='?', required=True,
                    help='Chroot path.')

parser.add_argument('-l', nargs='?', required=True,
                    help='Chroot version.')

parser.add_argument('-c', action='store_true', default=False,
                    help='Clean the chroot before building or installing.')

parser.add_argument('-I', nargs='+',
                    help='A list of packages to install into the chroot'
                    'environment before building.')

# parser.add_argument('packages', nargs='+', help='A list of packages to build.
# For all packages, use ' '"all"')

args = parser.parse_args()


def clean_chroot():
    """Creates a clean chroot.

    """
    for arch in ('i686', 'x86_64'):
        suffix = '32' if arch == 'i686' else '64'
        cdir = args.r + '/' + arch
        copydir = cdir + '/' + args.l + suffix
        if args.c:
            proc = subprocess.call(['sudo', 'mkdir', '-p', copydir])
            if proc > 0:
                logger.warning('Could not create chroot diretory "' + copydir +
                               '"')
            log_noprefix('Creating clean chroot at "' + copydir + '"')
            proc = subprocess.call(['sudo', 'rsync', '-a', '--delete', '-q',
                                    '-W', '-x', cdir + '/root/', copydir])
            if proc > 0:
                logger.warning('A problem occurred creating the clean chroot!')


def install_packages(packages):
    """Installs the packages passed as arguments into the chroot.

    """
    for pkg in packages:
        arch = 'i686' if 'i686' in pkg else 'x86_64'
        suffix = '32' if arch == 'i686' else '64'
        cdir = args.r + '/' + arch
        copydir = cdir + '/' + args.l + suffix
        pbname = os.path.basename(pkg)
        log_noprefix('Checking signature for "' + pkg + '"')
        proc = subprocess.call(['sudo', 'pacman-key', '-v', pkg + '.sig'])
        if proc > 0:
            logger.critical('Signature check failed!')
            sys.exit(1)
        log_noprefix('Copying "' + pkg + '" to the chroot')
        proc = subprocess.call(['sudo', 'cp', pkg, copydir + '/' + pbname])
        if proc > 0:
            logger.critical('Could not copy the package!')
            sys.exit(1)
        pac_cmd = 'pacman -U /' + pbname + ' --noconfirm'
        cmd = ['sudo', 'setarch', arch, 'mkarchroot', '-r', pac_cmd,
               copydir]
        log_noprefix('Installing "' + pkg + '"')
        proc = subprocess.call(cmd)
        if proc > 0:
            logger.warning('There was a problem installing the package!')
        proc = subprocess.call(['sudo', 'rm', copydir + '/' + pbname])
        if proc > 0:
            logger.warning('There was a problem removing the package!')


def set_new_sums(pkg):
    """Get new sums and change in the PKGBUILD

    """
    curdir = os.getcwd()
    os.chdir('devsrc/' + pkg)
    proc = subprocess.Popen(['makepkg', '-g'], stdout=subprocess.PIPE,
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
        log_noprefix('Generating hashes for "' + pkg + '"')
        new_pconf = pkg_conf.replace(pfsum[0], smsum[0])
        log_noprefix('Writing updated PKGBULID')
        with open('PKGBUILD', 'w') as p_file:
            p_file.write(new_pconf)
    else:
        log_noprefix('Hashes up-to-date for "' + pkg + '"')

    os.chdir(curdir)


def get_pkgbuild_version(pkg):
    """Get the version number for package from the PKGBUILD.

    Finds the PKGBUILD in the current directory.

    """
    with open('devsrc/' + pkg + '/PKGBUILD', 'r') as p_file:
        pkgb = p_file.read()
    # TODO: Merge these two regexs
    pkgver = re.findall(r'pkgver=([\d\w.]+)\n', pkgb)
    pkgrel = re.findall(r'pkgrel=(\d+)\n', pkgb)
    return pkgver[0] + '-' + pkgrel[0] or ''


def check_for_built_package(package, arch):
    """Check if package has been built and is stored in the backup/testing/
    directory.

    Uses the PKGBUILD in the current directory.

    """
    pkgver = get_pkgbuild_version(package)
    pkgname = '{}-{}-{}.pkg.tar.xz'.format(package, pkgver, arch)
    pkgpath = 'backup/testing/{}/{}/{}'.format(pkgver, arch, pkgname)
    if not os.path.exists(pkgpath):
        log('"' + pkgpath + '" does not exist')
        return False
    else:
        var = input('"' + pkgname + '" already exists, do you want to '
                    'overwrite? [Y/n] ')
        if var.lower == 'y' or var == '':
            return False
        else:
            log('Keeping "' + pkgpath + '"')
            return True


def check_for_package_dependencies(package, arch):
    """Install pre-built packages from backup/testing/

    """
    # First, get all of the dependencies including versioned dependencies.
    with open('devsrc/' + package + '/PKGBUILD', 'r') as p_file:
        pkgb = p_file.read()
    res = re.findall(r'(?:make)*depends=\((.*)\)\n', pkgb)
    pkgs = []
    for dep in res:
        pkgs.extend(re.findall(r'\'([\w\-=\.]+)\'', dep))
    if not pkgs:
        log.critical('Could not match package dependencies')
        sys.exit(1)

    # See if we have local packages available, otherwise fall back to pacman
    i_pkg_list = []
    for pkg in pkgs:
        if '=' in pkg:
            pkgname, pkgvers = pkg.split('=')
        else:
            pkgname = pkg
            pkgvers = ''
        # First search the backup directory
        pnamet = '{1}-{2}*{0}.pkg.tar.xz'
        pfoldr = 'backup/testing/*/{0}/'
        bpath = pfoldr + pnamet
        bpkg = glob.glob(bpath.format(arch, pkgname, pkgvers))

        # If there were no packages found in the backup directory, search the
        # 'depends' directory.
        if bpkg:
            i_pkg_list.extend(bpkg)
        else:
            dpath = 'depends/' + pnamet
            dpkg = glob.glob(dpath.format(arch, pkgname, pkgvers))
            if dpkg:
                i_pkg_list.extend(dpkg)

    if i_pkg_list:
        install_packages(i_pkg_list)


def build_packages():
    """Builds the packages in the devsrc directory.

    """
    for arch in ('i686', 'x86_64'):
        for pkg in PACKAGES:
            set_new_sums(pkg)
            suffix = '32' if arch == 'i686' else '64'
            cdir = args.r + '/' + arch
            cusdir = args.l + suffix
            subprocess.call('sudo rm -rf ' + cdir + '/' + cusdir + '/build/*',
                            shell=True)
            if check_for_built_package(pkg, arch):
                continue
            log('Building "' + pkg + '" for "' + arch + '"')
            check_for_package_dependencies(pkg, arch)
            os.chdir('devsrc/' + pkg)
            proc = subprocess.call(['sudo', 'setarch', arch, 'makechrootpkg',
                                    '-u', '-r', cdir, '-l', cusdir, '--',
                                    '-i'])
            if proc > 0:
                logger.critical('There was a problem building "' + pkg + '" '
                                'for "' + arch + '"')
                sys.exit(1)
            bpkg = glob.glob('*.pkg.tar.xz')
            if bpkg:
                bpkg = bpkg[0]
            else:
                bpkg = ''
            proc = subprocess.call(['gpg', '--detach-sign', '-u', '0EE7A126',
                                    '--use-agent', bpkg])
            if proc > 0:
                logger.warning('There was a problem signing "' + pkg + '"')
            proc = subprocess.call(['makepkg', '-S', '-f'])
            if proc > 0:
                logger.warning('There was a problem building the source '
                               'package for"' + pkg + '"')
            vers = re.search(r'[\w-]+-([\d\w\._]+-[\d])-(?:i686|x86_64)', bpkg)
            if vers:
                pvers = vers.group(1)
                vdira = '../../backup/testing/{}/{}/'.format(pvers, arch)
                proc = subprocess.call('mkdir -p ' + vdira, shell=True)
                if proc > 1:
                    logger.warning('There was an error creating the backup '
                                   'directory')
                log('Moving "{}" to "{}"'.format(bpkg, vdira))
                proc = subprocess.call('mv {}* {}'.format(bpkg, vdira),
                                       shell=True)
                if proc > 1:
                    logger.warning('There was a problem moving the package '
                                   'to the backup directory')
                source = glob.glob('*.src.tar.gz')[0]
                src_dest_t = '../../backup/testing/{}/'.format(pvers)
                proc = subprocess.call('mv {} {}'.format(source, src_dest_t),
                                       shell=True)
                if proc > 1:
                    logger.warning('There was a problem copying the package '
                                   'source to the backup directory')
            # Cleanup
            proc = subprocess.call('rm -r *.log src/ 2> /dev/null', shell=True)
            if proc > 1:
                logger.warning('There was a problem cleaning the working '
                               'files')

            os.chdir('../../')


def main():
    """The main function

    """
    log_note('Welcome!', 'package.py', 'white', 'bgred')

    if args.c:
        clean_chroot()

    if args.I:
        install_packages(args.I)

    build_packages()


if __name__ == '__main__':
    try:
        main()
    except (KeyboardInterrupt, EOFError):
        log('\nToodles.')
