#!/usr/bin/env python

from collections import deque
import colorsys
import copy
import logging
import optparse
import os
import pipes
import platform
import random
import re
import shutil
import sys
import yaml

from jinja2 import Environment, FileSystemLoader
from PIL import Image


logger = logging.getLogger(__name__)

def setup_logger(loglevel=logging.INFO, write_stdout=True, filename=None):
    if write_stdout:
        logger.addHandler(logging.StreamHandler())
    if filename is not None:
        logger.addHandler(logging.FileHandler(filename))
    logger.setLevel(loglevel)


COLOR_NAMES = [
    'black', 'red', 'green', 'yellow', 'blue', 'magenta', 'cyan', 'white',
    'alt_black', 'alt_red', 'alt_green', 'alt_yellow', 'alt_blue', 
    'alt_magenta', 'alt_cyan', 'alt_white',
]
DELETE_FLAG = '!!delete'
DOTTED_PATH_RE = re.compile('^\$\w+(\.\w+)*$')

CONFIG_HOME = os.environ.get('XDG_CONFIG_HOME') or os.path.join(
    os.environ.get('HOME'), '.config')
THEME_DIR = os.path.join(CONFIG_HOME, 'ta')
THEME_CONFIG = os.path.join(THEME_DIR, 'config.yaml')
THEME_TEMPLATES = os.path.join(THEME_DIR, 'templates')
THEMES_DIR = os.path.join(THEME_DIR, 'themes')

HOSTNAME = platform.node()


isdict = lambda obj: isinstance(obj, dict)


def _merge(data, updates):
    for key, value in updates.items():
        if key in data and isdict(value) and isdict(data[key]):
            _merge(data[key], value)
        else:
            data[key] = value
    return data


class Configuration(object):
    def __init__(self, config_file=None, mixins=None, **overrides):
        self.config_file = config_file or THEME_CONFIG
        self.mixins = mixins if mixins else ()
        self.host_overrides = os.path.join(THEME_DIR, '%s.yaml' % HOSTNAME)
        self.data = {}
        self.overrides = overrides

    def _read_file(self, config_file):
        with open(config_file) as fh:
            data = yaml.load(fh)
        if 'include' in data:
            include = data['include']
            if not isinstance(include, list):
                include = (include,)
            for path in include:
                _merge(data, self._read_file(path))
        return data

    def read(self):
        self.data = self._read_file(self.config_file)

        # Apply any host-specific overrides.
        if os.path.exists(self.host_overrides):
            _merge(self.data, self._read_file(self.host_overrides))
        for mixin in self.mixins:
            _merge(self.data['settings'], self._read_file(mixin))
        if self.overrides:
            _merge(self.data['settings'], self.overrides)
    
    def get_context(self):
        return copy.deepcopy(self.data['settings'])

    def get_templates(self):
        return self.data['templates'].items()

    def get_hooks(self, action):
        hooks = self.data.get('hooks') or {}
        return hooks.get(action) or []


class Renderer(object):
    def __init__(self, theme, template_dirs=None, dest_dir=None):
        self.theme = theme
        self.template_dirs = template_dirs
        self.dest_dir = dest_dir
        if self.template_dirs:
            loader = FileSystemLoader(self.template_dirs)
        else:
            loader = None
        self.env = Environment(loader=loader, extensions=['jinja2.ext.with_'])
        self.env.filters['brightness'] = self._brightness
        self.env.filters['hex_to_rgb'] = self._hex_to_rgb
        self.env.filters['hex_to_rrggbb'] = self._hex_to_rrggbb
        self.env.filters['hex_to_16bit'] = self._hex_to_16bit
        self.env.filters['i3_case'] = self._i3_case
        self.env.filters['percent_to_16bit'] = self._percent_to_16bit
        self.env.filters['readfile'] = self._readfile
        self.env.filters['shell_quote'] = self._shell_quote
        self.env.filters['yesno'] = self._yesno

    def _brightness(self, hex_color, percent):
        h = hex_color.lstrip('#')
        r, g, b = map(lambda x: int(x, 16), [h[i:i+2] for i in range(0, 6, 2)])
        h, l, s = colorsys.rgb_to_hls(r / 256., g / 256., b / 256.)
        if abs(percent) > 1:
            percent *= .01
        l = l + (l * percent)
        rgb = [i * 256 for i in colorsys.hls_to_rgb(h, l, s)]
        return '#%s' % ''.join(('%02x' % max(min(p, 255), 0) for p in rgb))

    def _hex_to_rgb(self, hex_val):
        val = hex_val.strip().lstrip('#')
        return [int(val[i:i+2], 16) for i in range(0, 6, 2)]

    def _hex_to_rrggbb(self, hex_val):
        val = hex_val.strip().lstrip('#')
        return [int(val[i:i+2] * 2, 16) for i in range(0, 6, 2)]

    def _hex_to_16bit(self, hex_val):
        hex_val = hex_val.lstrip('#')
        return ''.join(['#'] + [hex_val[i:i+2] * 2 for i in range(0, 6, 2)])

    def _i3_case(self, keys):
        if isinstance(keys, int):
            return keys

        chars = keys.split('+')
        A, Z = ord('A'), ord('Z')
        accum = []
        for char in chars:
            if len(char) == 1 and (A <= ord(char) <= Z):
                accum.append('Shift+%s' % char)
            else:
                accum.append(char)
        return '+'.join(accum)

    def _percent_to_16bit(self, value):
        # value is base 10 percentage. scale to 2^16
        conv = 1 << 16
        return int(conv * (value * .01))

    def _readfile(self, filename):
        for template_dir in self.template_dirs:
            filename = os.path.join(template_dir, filename)
            if os.path.exists(filename):
                with open(os.path.join(template_dir, filename)) as fh:
                    return yaml.load(fh)

    def _shell_quote(self, cmd):
        return pipes.quote(cmd)

    def _yesno(self, cond, yes, no):
        return yes if cond else no

    def render_templates(self, templates):
        for source, dest in templates:
            dest_path = os.path.join(self.dest_dir, dest)
            self._render_template(source, dest_path)

    def _render_template(self, source, dest):
        dir_name = os.path.dirname(dest)
        if not os.path.exists(dir_name):
            os.makedirs(dir_name)

        template = self.env.get_template(source)
        with open(dest, 'w') as fh:
            fh.write(template.render(**self.theme.context).encode('utf-8'))

    def render_command(self, command):
        return self.env.from_string(command).render(**self.theme.context)


class Source(object):
    def __init__(self, filename, context):
        self.filename = filename
        self.context = context

    def get_context(self):
        # _merge operates on the source dictionary in place.
        return _merge(copy.deepcopy(self.context), self.read_values())

    def read_values(self):
        raise NotImplementedError


class XresourcesSource(Source):
    mapping = {
        'background': 'background',
        'foreground': 'foreground',
        'colorit': 'italics',
        'colorul': 'underline'}
    rgx = re.compile('.*?(color[^:]+|background|foreground):'
                     '[^\#]*?(#[\da-f]{6})')

    def read_values(self):
        mapping = self.mapping.copy()
        for i, color_name in enumerate(COLOR_NAMES):
            mapping['color%s' % i] = color_name

        colors = {}
        with open(self.filename) as fh:
            for line in fh.readlines():
                if line.startswith('!'):
                    continue
                match_obj = self.rgx.search(line.lower())
                if match_obj:
                    var, color = match_obj.groups()
                    if var in mapping:
                        colors[mapping[var]] = color

        return colors


class YAMLConfigSource(Source):
    def read_values(self):
        with open(self.filename) as fh:
            return yaml.load(fh)


class Theme(object):
    conversions = {
        'true': True,
        'false': False,
        'null': None,
        '[]': [],
        '{}': {},
    }

    def __init__(self, source_file, base_context):
        self.base_context = base_context
        self.source_file = source_file

        self.source = self._create_source()
        self.source_context = self.source.get_context()
        self.context = self._resolve()

    def _create_source(self):
        if self.source_file.lower().endswith('.yaml'):
            SourceClass = YAMLConfigSource
        else:
            SourceClass = XresourcesSource
        return SourceClass(self.source_file, self.base_context)

    def _resolve(self):
        def _resolve(obj):
            if isinstance(obj, dict):
                obj_copy = obj.copy()
                for key, value in obj.items():
                    obj_copy[key] = _resolve(value)
                return obj_copy
            elif isinstance(obj, list):
                return [_resolve(item) for item in obj]
            elif isinstance(obj, basestring) and DOTTED_PATH_RE.match(obj):
                # Resolve references of n-degrees.
                obj = obj.lstrip('$')  # Remove variable identifier string.
                ctx = self.source_context
                for part in obj.split('.'):
                    if part in ctx:
                        ctx = ctx[part]
                    else:
                        return obj
                return _resolve(ctx)
            else:
                return obj

        context = _resolve(self.source_context.copy())
        return self.add_theme_settings(context)

    def add_theme_settings(self, context):
        context.setdefault(
            'color_list', 
            [context.get(name) for name in COLOR_NAMES])
        return context

    def diff(self):
        type_match = lambda b, t, T: isinstance(b, T) and isinstance(t, T)
        identical = object()

        def check(bval, tval):
            if type_match(bval, tval, dict):
                return trace_dict(bval, tval)
            elif type_match(bval, tval, list):
                return trace_list(bval, tval)
            elif type_match(bval, tval, basestring):
                return tval if bval != tval else identical
            elif type_match(bval, tval, (int, float)):
                return tval if bval != tval else identical
            elif (bval is None) and (tval is None):
                return identical
            else:
                try:
                    diff = identical if bval == tval else tval
                except:
                    diff = tval
                return diff

        def trace_list(base, theme):
            if len(base) != len(theme):
                return theme

            accum = []
            changes = False
            for i in range(len(theme)):
                bval = base[i]
                tval = theme[i]
                diff = check(bval, tval)
                if diff is not identical:
                    changes = True
                    accum.append(diff)
                else:
                    accum.append(bval)

            if changes:
                return accum
            else:
                return identical

        def trace_dict(base, theme):
            accum = {}
            additions = set(theme) - set(base)
            for addition in additions:
                accum[addition] = theme[addition]

            changes = bool(additions)
            for key in base:
                assert key in theme, ('"%s" missing in theme.' % key)
                diff = check(base[key], theme[key])
                if diff is not identical:
                    changes = True
                    accum[key] = diff

            if changes:
                return accum
            else:
                return identical

        # Return a diff of the (unresolved) overrides unique to the theme.
        return trace_dict(self.base_context, self.source_context)

    def remove_paths(self, paths):
        for path in paths:
            src_curr = self.source_context
            base_curr = self.base_context

            parts = path.split('.')
            parents, key = parts[:-1], parts[-1]
            for parent in parents:
                if parent not in src_curr:
                    break
                src_curr = src_curr[parent]
                base_curr = base_curr[parent]
            else:
                src_curr.pop(key, None)
                src_curr[key] = copy.deepcopy(base_curr[key])

    def update_source_context(self, data):
        updates = {}

        for key_path, value in data.items():
            parts = key_path.split('.')
            path, key = parts[:-1], parts[-1]
            curr = updates
            for subkey in path:
                if subkey not in curr:
                    curr[subkey] = {}
                curr = curr[subkey]

            if value == DELETE_FLAG:
                curr.pop(key, None)
            else:
                if value in self.conversions:
                    value = self.conversions[value]
                curr[key] = value

        _merge(self.source_context, updates)

    def get_value(self, key_path):
        parts = key_path.split('.')
        path, key = parts[:-1], parts[-1]
        curr = self.context
        for subkey in path:
            if subkey not in curr:
                return
            curr = curr[subkey]

        try:
            return curr[key]
        except KeyError:
            pass


class TA(object):
    def __init__(self, config_file=None, template_dirs=None, dest_dir=None,
                 themes_dir=None, mixins=None, **extra_config):
        self.config = Configuration(config_file, mixins, **extra_config)
        self.template_dirs = template_dirs or (THEME_TEMPLATES,)
        self.dest_dir = dest_dir or THEME_DIR
        self.themes_dir = themes_dir or THEMES_DIR
        try:
            self.config.read()
        except Exception as exc:
            raise RuntimeError('Error reading theme file: %s\n%s' % (
                config_file, exc))

    def get_filename(self, name, full_context=False):
        if full_context:
            name = 'full-context/%s' % name
        return os.path.join(self.themes_dir, '%s.yaml' % name)

    def get_dir(self, name):
        return os.path.join(self.dest_dir, name)

    def _default_context(self, name):
        return {
            'home': os.environ['HOME'],
            'hostname': HOSTNAME,
            'theme': name,
            'theme_dir': self.get_dir(name),
        }

    def get_base_context(self, name):
        return _merge(self.config.get_context(), self._default_context(name))

    def load_theme(self, name, full_context=False):
        source_file = self.get_filename(name, full_context=full_context)
        try:
            return Theme(source_file, self.get_base_context(name))
        except:
            print 'Error loading theme config for "%s".' % name
            raise

    def save_context(self, filename, context):
        # Split the context so bare key/values appear before structures.
        first, second = {}, {}
        for key, value in context.items():
            if isinstance(value, (list, dict)):
                second[key] = value
            else:
                first[key] = value

        with open(filename, 'w') as fh:
            yaml.dump(first, fh, default_flow_style=False)
            if second:
                yaml.dump(second, fh, default_flow_style=False)

    def run_hooks(self, action, theme):
        renderer = Renderer(theme)
        for cmd_raw in self.config.get_hooks(action):
            os.system(renderer.render_command(cmd_raw))

    def render_theme(self, name, theme):
        # File paths we'll use to store rendered templates and configs.
        dest_dir = self.get_dir(name)
        dest_context_file = self.get_filename(name, full_context=True)
        dest_diff_file = self.get_filename(name)

        # Create directory structure if it doesn't exist.
        parent_dir = os.path.dirname(dest_context_file)
        if not os.path.exists(parent_dir):
            os.makedirs(parent_dir)

        # Render the templates using the theme-specific values.
        renderer = Renderer(theme, self.template_dirs, dest_dir)
        renderer.render_templates(self.config.get_templates())

        # Save the fully-populated source context, as well as the smaller
        # diff which contains only the theme-specific overrides.
        self.save_context(dest_context_file, theme.source_context)
        self.save_context(dest_diff_file, theme.diff())

    def add(self, name, source_file):
        theme = Theme(source_file, self.get_base_context(name))
        self.render_theme(name, theme)
        self.run_hooks('add', theme)

    def _reassign_current(self, name):
        if not os.path.exists(self.get_dir(name)):
            raise RuntimeError('Cannot set theme: "%s" not found.' % name)

        current = self.current()
        if name == current:
            return

        path = self.get_dir('current')
        if os.path.islink(path):
            os.unlink(path)
        elif os.path.exists(path):
            raise RuntimeError('Error, cannot unlink current theme.')

        os.symlink(self.get_dir(name), path)

    def set_theme(self, name, full_context=False, rerender=True):
        # If the source YAML definition exists but the rendered theme doesn't,
        # then create it first.
        theme_def_exists = os.path.exists(self.get_filename(name))
        theme_files_exist = os.path.exists(self.get_dir(name))
        if theme_def_exists and not theme_files_exist:
            self.update(name, run_hooks=False)

        # Update "current" symlink to point to the given them.
        self._reassign_current(name)

        theme = self.load_theme(name, full_context=full_context)
        if rerender:
            self.render_theme(name, theme)

        self.run_hooks('set', theme)

    def list_themes(self):
        return sorted(os.path.splitext(f)[0] 
                      for f in os.listdir(self.themes_dir)
                      if f.endswith('.yaml'))

    def update(self, name, run_hooks=True, full_context=False):
        theme = self.load_theme(name, full_context=full_context)
        self.render_theme(name, theme)

        if run_hooks and (name == self.current()):
            self.run_hooks('add', theme)
            self.run_hooks('set', theme)

    def current(self):
        current = self.get_dir('current')
        if os.path.exists(current):
            return os.path.basename(os.path.realpath(current))

    def rename(self, src, dest, delete=False):
        if src == 'current':
            src = self.current()
        is_current = src == self.current()

        # Rename the theme definition.
        if delete:
            os.rename(self.get_filename(src), self.get_filename(dest))

            # Remove the full context file if it exists.
            self.delete(src)
        else:
            shutil.copy(self.get_filename(src), self.get_filename(dest))

        if is_current:
            self.set_theme(dest)

    def delete(self, name):
        path = self.get_dir(name)
        if os.path.exists(path):
            shutil.rmtree(path)
        for full_context in (True, False):
            filename = self.get_filename(name, full_context=full_context)
            if os.path.exists(filename):
                os.unlink(filename)

    def diff(self, name, full_context=False):
        theme = self.load_theme(name, full_context=full_context)
        return theme.diff()

    def list_mixins(self):
        return [f[:-5] for f in os.listdir(os.path.join(THEME_DIR, 'mixins'))
                if f.endswith('.yaml')]

    def update_keys(self, name, data):
        theme = self.load_theme(name, full_context=True)
        theme.update_source_context(data)
        self.render_theme(name, theme)

    def get_values(self, name, *keys):
        accum = []
        theme = self.load_theme(name, full_context=True)
        for key in keys:
            accum.append(theme.get_value(key))
        return accum

    def reset(self, name, *paths):
        theme = self.load_theme(name, full_context=False)
        theme.remove_paths(paths)
        self.render_theme(name, theme)


def _normalize_name(ta, name, default_current=True, multi=True):
    if not name and not default_current:
        raise RuntimeError('Expected a theme name but none was given.')
    elif name == 'all' and not multi:
        raise RuntimeError('This command does not accept "all" as a name.')

    if name == 'all':
        return ta.list_themes()
    return (name,) if multi else name

def _filter_paths(data, paths):
    if not paths:
        return data
    result = {}
    for path in paths:
        curr = data
        try:
            for part in path.split('.'):
                curr = curr[part]
        except KeyError:
            continue
        else:
            result[part] = curr
    return result

def update(ta, name, full_context=False):
    for name in _normalize_name(ta, name):
        ta.update(name, full_context=full_context)

def remove(ta, name):
    for name in _normalize_name(ta, name, default_current=False):
        ta.delete(name)

def _green(s):
    return '\033[92m%s\033[0m' % s

def _red(s):
    return '\033[91m%s\033[0m' % s

def _highlight(s):
    return '\033[0;32m%s\033[0m' % s

def _print_diff(path, bval, tval):
    bval = str(bval) if bval is not None else None
    tval = str(tval)
    key = '.'.join(path)
    if bval is None:
        print('%s: %s' % (key, _green(tval)))
    else:
        k1 = len(key) + len(bval)
        if (k1 + len(tval)) < 72:
            print('%s: %s -> %s' % (key, _red(bval), _green(tval)))
        elif k1 < 78:
            print('%s: %s' % (key, _red(bval)))
            print(' ' * (len(key) + 1)),
            print(_green(tval))
        else:
            print(key)
            print(_red('  %s' % bval))
            print(_green('  %s' % tval))

def print_diff(theme, paths):
    # Grab all the overrides.
    diff = theme.diff()
    base_ctx = theme.base_context
    root = []
    nested = []
    diff = _filter_paths(diff, paths)
    for key, value in diff.items():
        tgt = nested if isinstance(value, dict) else root
        tgt.append(key)

    stack = deque((k,) for k in sorted(root) + sorted(nested))
    while stack:
        path = stack.popleft()
        curr_base = base_ctx
        curr_theme = diff
        for key in path:
            curr_theme = curr_theme[key]
            if key in curr_base:
                curr_base = curr_base[key]
            else:
                _print_diff(path, None, curr_theme)
                break
        else:
            if isinstance(curr_theme, dict):
                for key in sorted(curr_theme, reverse=True):
                    stack.appendleft(path + (key,))
            else:
                _print_diff(path, curr_base, curr_theme)

def display_diffs(ta, name, full_context=False, paths=None):
    for i, name in enumerate(_normalize_name(ta, name)):
        theme = ta.load_theme(name, full_context=full_context)
        if i != 0: print '\n\n'
        print name
        print '=' * len(name)
        print_diff(theme, paths)

def show_theme(ta, name, full_context=False, paths=None):
    for i, name in enumerate(_normalize_name(ta, name)):
        theme = ta.load_theme(name, full_context=full_context)
        data = theme.context if full_context else theme.source_context
        if i != 0: print '\n\n'
        _print_theme(data, paths)

def _print_theme(data, paths):
    print yaml.dump(_filter_paths(data, paths), default_flow_style=False)

def display_values(value_list):
    for value in value_list:
        if isinstance(value, dict) and not value:
            print '{}'
        elif isinstance(value, list) and not value:
            print '[]'
        elif value is None:
            print 'null'
        elif value is True or value is False:
            print str(value).lower()
        else:
            print value


def main(ta, action, name, source, set_theme=False, full_context=False,
         paths=None, color=True, **_):
    if action == 'ls':
        themes = ta.list_themes()
        current = ta.current()
        for theme in themes:
            if theme == current and color:
                print '\033[3;46;30m%s\033[0m' % theme
            else:
                print theme
    elif action == 'current':
        name = ta.current()
        if not name:
            print 'Unable to determine current theme.'
        else:
            print name
    elif action == 'show':
        show_theme(ta, name, full_context=full_context, paths=paths)
    elif action == 'update':
        update(ta, name, full_context=full_context)
    elif action == 'rm':
        remove(ta, name)
    elif action in ('rename', 'copy'):
        ta.rename(name, source, action=='rename')
    elif action == 'add':
        ta.add(name, source)
        if set_theme:
            ta.set_theme(name, rerender=False)
    elif action == 'diff':
        display_diffs(ta, name, full_context=full_context, paths=paths)
    elif action == 'mixins':
        mixins = ta.list_mixins()
        print '\n'.join(sorted(mixins))
    elif action == 'set':
        ta.set_theme(name, full_context=full_context)
    elif action == 'setval':
        ta.update_keys(name, source)
    elif action == 'getval':
        display_values(ta.get_values(name, *source))
    elif action == 'reset':
        if 'all' in name:
            name = ['all']
        accum = []
        for n in name:
            for normalized in _normalize_name(ta, n):
                ta.reset(normalized, *paths)
                accum.append(normalized)
        print 'Reset the following paths:'
        print '\n'.join(paths)
        print '\nUpdated the following themes:'
        print '\n'.join(accum)

def validate_mixins(mixins):
    # Validate any mixins.
    if not mixins: return

    mixins = []
    for mixin in opts.mixins:
        mixin = '%s.yaml' % mixin
        if '/' not in mixin:
            mixin = os.path.join(THEME_DIR, 'mixins', mixin)
        mixins.append(mixin)

    invalid = [mixin for mixin in mixins
               if not os.path.exists(mixin)]
    if invalid:
        panic('The following mixins were not found:\n%s' 
              % ('\n'.join(invalid)))
    return mixins

def get_parser():
    parser = optparse.OptionParser(usage=(
        'usage: %prog ['
        'show|add|set|update|ls|rm|rename|diff|mixins|setval|getval|reset] '
        'name [color source] [options]'))
    ao = parser.add_option
    ao('-a', '--set', dest='set_theme', action='store_true', 
       metavar='THEME_NAME')
    ao('-c', '--config', dest='config_file', metavar='CONFIG.YAML')
    ao('-d', '--dest-dir', dest='dest_dir', help='path for rendered configs')
    ao('-f', '--full-context', dest='full_context', action='store_true',
       help='use full context definition rather than overrides-only')
    ao('-l', '--logfile', dest='logfile', metavar='FILE')
    ao('-m', '--mixin', dest='mixins', action='append',
       help=('Mix-in the settings from any number of additional settings '
             'files. If more than one mixin is provided, then the first mixin '
             'takes precendence.'),
       metavar='MIXIN-NAME')
    ao('-n', '--name', dest='name', help='specify theme name to act on.')
    ao('-o', '--override', dest='overrides', action='append',
       help='setting overrides, as "setting=value", can use multiple times',
       metavar='KEY=VALUE')
    ao('-p', '--path', dest='paths', action='append',
       help=('Only show values that match the given path (applies to "diff" '
             'and "show" commands)'))
    ao('-t', '--template-dir', dest='template_dirs', action='append',
       help=('Path to templates. Can be specified multiple times if multiple '
             'template directories exist.'),
       metavar='DIRECTORY')
    ao('-v', '--verbose', action='store_true', dest='verbose', 
       help='Verbose logging')
    ao('-w', '--wallpaper', dest='wallpaper', help='Applies to "add" action')
    ao('-x', '--no-delete', default=True, dest='delete', action='store_false',
       help=('Treat rename operation as copy rather than move.'))
    ao('--no-color', dest='color', action='store_false', default=True,
       help='Do not use any terminal colors when displaying output.')
    return parser


def panic(msg):
    print >> sys.stderr, _red(msg)
    sys.exit(1)


if __name__ == '__main__':
    parser = get_parser()
    opts, args = parser.parse_args()

    if not args:
        args = ('show', 'current')

    action_to_args = {
        'ls': 1,
        'set': 2,
        'add': 3,
        'current': 1,
        'show': 1,
        'update': 1,
        'rm': 2,
        'rename': 2,
        'diff': 1,
        'mixins': 1,
        'setval': 3,
        'getval': 2,
        'lsa': 1,  # Undocumented, list actions.
        'set': 1,
        'set_value': 1,
        'get_value': 1,
        'reset': 1,
    }
    aliases = {
        'apply': 'set',
        'd': 'diff',
        'generate': 'add',
        'get_value': 'getval',
        'key': 'setval',
        'l': 'ls',
        'm': 'mixins',
        'mv': 'rename',
        's': 'set',
        'set_value': 'setval',
        'u': 'update',
        'val': 'getval',
    }
    action = args[0]
    action = aliases.get(action, action)

    name = source = None
    extra_config = {}

    if action not in action_to_args:
        panic('Unknown action "%s"' % action)
    elif len(args) < action_to_args[action]:
        panic('"%s" missing required arguments' % action)
    elif action == 'rename':
        if len(args) == 2:
            name, source = 'current', args[1]
        else:
            name, source = args[1:3]
        if not opts.delete:
            action = 'copy'
    elif action == 'setval':
        if len(args) % 2 != 1:
            panic('Uneven number of key/value pairs.')
        name = 'current'
        source = dict(zip(args[1::2], args[2::2]))
    elif action == 'getval':
        name = 'current'
        source = args[1:]
    elif action == 'reset': 
        if not opts.paths:
            panic('The reset action requires at least one path be specified.')
        else:
            name = args[1:] or ['current']
    elif len(args) == 3:
        name, source = args[1:]
    elif len(args) == 2:
        name = args[1]
    elif action in ('show', 'update', 'diff') and len(args) == 1:
        name = 'current'
    elif action == 'lsa':
        print '\n'.join(sorted(action_to_args))
        sys.exit(0)

    # Collect overrides.
    for override in (opts.overrides or ()):
        key, value = override.split('=', 1)
        key, value = key.strip().lower(), value.strip().lower()
        if key in extra_config:
            panic('"%s" already specified.' % key)
        extra_config[key] = value

    if opts.wallpaper:
        extra_config.setdefault('wallpaper', {})
        extra_config['wallpaper']['filename'] = opts.wallpaper

    ta = TA(
        opts.config_file,
        opts.template_dirs,
        opts.dest_dir,
        mixins=validate_mixins(opts.mixins),
        **extra_config)

    if name == 'current':
        if opts.name and opts.name != 'current':
            name = opts.name
        else:
            name = opts.name or ta.current()
        if not name:
            print 'Current theme is not specified.'
            sys.exit(1)

    options = vars(opts)
    options.pop('name', None)
    main(ta, action, name, source, **options)
