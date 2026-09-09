"""Offline regressions for export review findings; no APIs or app launches."""
import contextlib
import ctypes
import ctypes.util
import importlib.util
import io
import json
import os
from pathlib import Path
import runpy
import subprocess
import tempfile
import unittest
from unittest import mock

ROOT = Path(__file__).resolve().parents[1]


class ReviewFixes(unittest.TestCase):
    def setUp(self):
        (ROOT / '.tmp').mkdir(exist_ok=True)
        temp = tempfile.TemporaryDirectory(dir=ROOT / '.tmp')
        self.addCleanup(temp.cleanup)
        self.work = Path(temp.name)
        self.env = dict(os.environ, HOME=str(self.work), HERDR_BIN_PATH='',
                        TMPDIR=str(self.work), PYTHONDONTWRITEBYTECODE='1')
        self.sync = runpy.run_path(str(ROOT / 'bin/ytmusic-sync'))['main'].__globals__
        for key, value in {'MUSIC_DIR': 'music', 'PLAYLIST_DIR': 'playlists',
                           'STATE_DIR': 'state', 'STATE_FILE': 'state/state.json',
                           'ARCHIVE_FILE': 'state/archive.txt', 'TRASH_DIR': 'state/trash',
                           'STRAWBERRY_DB': 'strawberry.db'}.items():
            self.sync[key] = self.work / value
        self.sync['fetch_music_playlists'] = mock.Mock(return_value=[{'id': 'PL1', 'title': 'Named'}])
        self.sync['log'] = mock.Mock()

    def main(self, *args):
        with mock.patch.dict(os.environ, self.env), mock.patch('sys.argv', ['ytmusic-sync', '--channel', 'UCoffline', *args]):
            self.sync['main']()

    def snapshot(self):
        return {str(p.relative_to(self.work)): p.read_bytes() if p.is_file() else None
                for p in self.work.rglob('*')}

    def test_discovery_failure_aborts_before_any_mutation_even_with_partial_stdout(self):
        self.sync['PLAYLIST_DIR'].mkdir()
        (self.sync['PLAYLIST_DIR'] / 'unrelated.m3u8').write_bytes(b'keep playlist')
        self.sync['STATE_DIR'].mkdir()
        self.sync['STATE_FILE'].write_text('{"playlists": {}}')
        self.sync['ARCHIVE_FILE'].write_text('keep archive')
        self.sync['MUSIC_DIR'].mkdir()
        (self.sync['MUSIC_DIR'] / 'song [abcdefghijk].opus').write_bytes(b'keep audio')
        self.sync['STRAWBERRY_DB'].write_bytes(b'keep DB')
        for output in ('', 'abcdefghijk\n'):
            with self.subTest(output=output):
                before = self.snapshot()
                stderr = io.StringIO()
                proc = subprocess.CompletedProcess([], 1, output, 'ERROR: HTTP Error 403: private-value\nAuthorization: secret-value\x1b[31m')
                with mock.patch.object(self.sync['subprocess'], 'run', return_value=proc) as run, contextlib.redirect_stderr(stderr):
                    with self.assertRaises(SystemExit) as raised:
                        self.main('--prune', '--relink')
                self.assertEqual(raised.exception.code, 1)
                self.assertEqual(run.call_count, 1)
                self.assertEqual(self.snapshot(), before)
                self.assertIn('HTTP Error 403', stderr.getvalue())
                self.assertNotIn('private-value', stderr.getvalue())
                self.assertNotIn('secret-value', stderr.getvalue())
                self.assertNotIn('\x1b', stderr.getvalue())

    def test_shelf_expansion_failure_aborts_before_mutation(self):
        self.sync['fetch_music_playlists'] = runpy.run_path(str(ROOT / 'bin/ytmusic-sync'))['fetch_music_playlists']
        client = mock.Mock()
        client.get_user.return_value = {'playlists': {'params': 'next', 'results': [{'playlistId': 'PLvisible', 'title': 'Visible'}]}}
        client.get_user_playlists.side_effect = RuntimeError('private diagnostic')
        module = mock.Mock(YTMusic=mock.Mock(return_value=client))
        mutations = {name: mock.Mock() for name in ('write_m3u', 'prune_orphans', 'save_state')}
        self.sync.update(mutations)
        self.sync['fetch_playlist_tracks'] = mock.Mock(return_value=[])
        stderr = io.StringIO()
        with mock.patch.dict('sys.modules', {'ytmusicapi': module}), contextlib.redirect_stderr(stderr):
            with self.assertRaises(SystemExit):
                self.main('--no-download', '--prune')
        for action in mutations.values():
            action.assert_not_called()
        self.assertEqual(self.snapshot(), {})
        self.assertNotIn('private diagnostic', stderr.getvalue())

    def test_channel_discovery_failure_rejects_partial_json_without_writes(self):
        proc = subprocess.CompletedProcess([], 1, '{"channel_id":"UCoffline"}', 'private diagnostic')
        with mock.patch.object(self.sync['subprocess'], 'run', return_value=proc), contextlib.redirect_stderr(io.StringIO()):
            with self.assertRaises(SystemExit):
                self.sync['run_json'](['yt-dlp', 'offline'])
        self.assertEqual(self.snapshot(), {})

    def test_successful_sync_retains_unrelated_and_stale_playlists_even_with_prune(self):
        self.sync['PLAYLIST_DIR'].mkdir()
        for name in ('unrelated', 'old-title'):
            (self.sync['PLAYLIST_DIR'] / f'{name}.m3u8').write_bytes(b'keep playlist')
        self.sync['fetch_playlist_tracks'] = mock.Mock(return_value=[])
        with mock.patch.object(self.sync['subprocess'], 'run', side_effect=AssertionError('unexpected subprocess')):
            self.main('--no-download', '--prune')
        for name in ('unrelated', 'old-title'):
            self.assertEqual((self.sync['PLAYLIST_DIR'] / f'{name}.m3u8').read_bytes(), b'keep playlist')
        self.assertEqual((self.sync['PLAYLIST_DIR'] / 'Named.m3u8').read_text(), '#EXTM3U\n')

    def test_replaced_playlist_has_unique_recoverable_backup_before_each_change(self):
        self.sync['PLAYLIST_DIR'].mkdir()
        target = self.sync['PLAYLIST_DIR'] / 'Named.m3u8'
        first = b'\xffprivate original\r\n'
        target.write_bytes(first)
        playlists = {'PL1': {'title': 'Named', 'tracks': []}}
        self.sync['write_m3u'](playlists, {})
        backups = [p for p in self.sync['PLAYLIST_DIR'].iterdir() if p != target]
        self.assertEqual([p.read_bytes() for p in backups], [first])
        with mock.patch.object(Path, 'write_bytes', side_effect=AssertionError('unchanged output must not be truncated')):
            self.sync['write_m3u'](playlists, {})
        self.assertEqual(len(list(self.sync['PLAYLIST_DIR'].iterdir())), 2)
        target.write_bytes(b'second version')
        self.sync['write_m3u'](playlists, {})
        self.assertEqual(sorted(p.read_bytes() for p in self.sync['PLAYLIST_DIR'].iterdir() if p != target),
                         sorted([first, b'second version']))

    def test_backup_failure_leaves_original_untouched(self):
        self.sync['PLAYLIST_DIR'].mkdir()
        target = self.sync['PLAYLIST_DIR'] / 'Named.m3u8'
        target.write_bytes(b'original')
        original_open = Path.open

        def deny_backup(path, mode='r', *args, **kwargs):
            if mode == 'xb':
                raise PermissionError('fixture backup denied')
            return original_open(path, mode, *args, **kwargs)

        with mock.patch.object(Path, 'open', deny_backup):
            with self.assertRaises(PermissionError):
                self.sync['write_m3u']({'PL1': {'title': 'Named', 'tracks': []}}, {})
        self.assertEqual(target.read_bytes(), b'original')

    def test_playlist_symlink_refused_without_touching_referent(self):
        self.sync['PLAYLIST_DIR'].mkdir()
        referent = self.work / 'outside'
        referent.write_bytes(b'keep')
        target = self.sync['PLAYLIST_DIR'] / 'Named.m3u8'
        target.symlink_to(referent)
        with contextlib.redirect_stderr(io.StringIO()), self.assertRaises(SystemExit):
            self.sync['write_m3u']({'PL1': {'title': 'Named', 'tracks': []}}, {})
        self.assertEqual(referent.read_bytes(), b'keep')
        self.assertTrue(target.is_symlink())

    def test_proof_gate_rejects_missing_or_nonexecutable_runner(self):
        cfg = self.work / '.make-aron'
        cfg.mkdir()
        tests = self.work / 'tests'
        tests.mkdir()
        (tests / 'test_new.py').write_text('assert False\n')
        tools = self.work / 'tools'
        tools.mkdir()
        git = tools / 'git'
        git.write_text('''#!/usr/bin/env bash
case "$1" in
  rev-parse) echo .git ;;
  diff) echo tests/test_new.py ;;
  ls-files) ;;
  worktree) ;;
  *) exit 99 ;;
esac
''')
        git.chmod(0o755)
        blocked = self.work / 'blocked-runner'
        blocked.write_text('#!/bin/sh\nexit 1\n')
        for command, code in [('dotfiles_fixture_missing_runner', 127), (str(blocked), 126)]:
            with self.subTest(code=code):
                (cfg / 'gates.json').write_text(json.dumps({'cmd': {'test_one': command + ' {file}'}}))
                result = subprocess.run(['bash', str(ROOT / 'config/agents/skills/make-max-test-aron/gates/prove-test.sh')],
                                        cwd=self.work, env=dict(self.env, PATH=f'{tools}:{os.environ["PATH"]}'),
                                        capture_output=True, text=True)
                self.assertEqual(result.returncode, 2, result.stdout + result.stderr)
                self.assertIn(f'runner exited {code}', result.stderr)
                self.assertNotIn('PASS(G11)', result.stdout)


class DesktopExec(unittest.TestCase):
    def test_native_glib_decodes_all_launchers_without_launching_apps(self):
        library = os.environ.get('DOTFILES_TEST_GLIB') or ctypes.util.find_library('glib-2.0')
        if not library:
            self.skipTest('GLib unavailable; set DOTFILES_TEST_GLIB to inspected native library')
        glib = ctypes.CDLL(library)
        glib.g_key_file_new.restype = ctypes.c_void_p
        glib.g_key_file_load_from_file.argtypes = [ctypes.c_void_p, ctypes.c_char_p, ctypes.c_int, ctypes.POINTER(ctypes.c_void_p)]
        glib.g_key_file_get_string.argtypes = [ctypes.c_void_p, ctypes.c_char_p, ctypes.c_char_p, ctypes.POINTER(ctypes.c_void_p)]
        glib.g_key_file_get_string.restype = ctypes.c_void_p
        glib.g_key_file_free.argtypes = [ctypes.c_void_p]
        glib.g_free.argtypes = [ctypes.c_void_p]
        glib.g_error_free.argtypes = [ctypes.c_void_p]
        glib.g_shell_parse_argv.argtypes = [ctypes.c_char_p, ctypes.POINTER(ctypes.c_int), ctypes.POINTER(ctypes.POINTER(ctypes.c_char_p)), ctypes.POINTER(ctypes.c_void_p)]
        glib.g_strfreev.argtypes = [ctypes.POINTER(ctypes.c_char_p)]
        for path in sorted(ROOT.rglob('*.desktop')):
            if '.tmp' in path.parts:
                continue
            with self.subTest(path=path.relative_to(ROOT)):
                key = glib.g_key_file_new()
                error = ctypes.c_void_p()
                value = None
                argv = ctypes.POINTER(ctypes.c_char_p)()
                try:
                    self.assertTrue(glib.g_key_file_load_from_file(key, os.fsencode(path), 0, ctypes.byref(error)))
                    value = glib.g_key_file_get_string(key, b'Desktop Entry', b'Exec', ctypes.byref(error))
                    self.assertFalse(error.value, 'GLib rejected Exec key-file escape')
                    argc = ctypes.c_int()
                    self.assertTrue(glib.g_shell_parse_argv(ctypes.string_at(value), ctypes.byref(argc), ctypes.byref(argv), ctypes.byref(error)))
                    args = [argv[i].decode() for i in range(argc.value)]
                    if args[:2] == ['sh', '-c']:
                        self.assertEqual(len(args), 3)
                        self.assertIn('"$HOME/', args[2])
                        self.assertNotIn('\\', args[2])
                finally:
                    if value:
                        glib.g_free(value)
                    if error.value:
                        glib.g_error_free(error)
                    if argv:
                        glib.g_strfreev(argv)
                    glib.g_key_file_free(key)

    def test_offline_validator_rejects_old_exec_escape(self):
        spec = importlib.util.spec_from_file_location('desktop_exec', ROOT / 'scripts/desktop_exec.py')
        module = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(module)
        with self.assertRaises(ValueError):
            module.validate_exec(r'sh -c "exec \"\$HOME/projects/example\""')
        with self.assertRaises(ValueError):
            module.validate_exec('sh -c "unterminated')


if __name__ == '__main__':
    unittest.main()
