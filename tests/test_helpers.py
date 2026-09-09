"""Offline behavior checks. No installs, real remotes, HOME writes, or APIs."""
import json
import os
from pathlib import Path
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]


class Helpers(unittest.TestCase):
    def setUp(self):
        (ROOT / '.tmp').mkdir(exist_ok=True)
        self.temp = tempfile.TemporaryDirectory(dir=ROOT / '.tmp')
        self.addCleanup(self.temp.cleanup)
        self.work = Path(self.temp.name)
        self.home = self.work / 'home'
        self.home.mkdir()
        self.mock = self.work / 'mock'
        self.mock.mkdir()
        self.env = dict(os.environ, HOME=str(self.home),
                        PATH=f'{self.mock}:{os.environ["PATH"]}',
                        CALLS=str(self.work / 'calls'),
                        RS_CONFIG=str(self.work / 'remove-silence.conf'),
                        XDG_CONFIG_HOME=str(self.home / '.config'),
                        HERDR_BIN_PATH='')
        self.manifest = self.work / 'repos.tsv'

    def stub(self, name, body):
        p = self.mock / name
        p.write_text('#!/usr/bin/env bash\nset -eu\n' + body)
        p.chmod(0o755)

    def run_helper(self, name, *args, **kwargs):
        return subprocess.run([str(ROOT / 'bin' / name), *args], env=self.env,
                              text=True, capture_output=True, **kwargs)

    def clone(self, text, *args):
        self.manifest.write_text(text)
        self.env['DOTFILES_REPOS_MANIFEST'] = str(self.manifest)
        return self.run_helper('clone-repos', *args)

    def test_clone_existing_checkout_directory_file_and_dangling_link_untouched(self):
        root = self.home / 'projects'
        root.mkdir()
        (root / 'checkout').mkdir()
        (root / 'checkout' / '.git').mkdir()
        (root / 'directory').mkdir()
        (root / 'file').write_text('keep')
        (root / 'link').symlink_to(root / 'absent')
        self.stub('git', 'exit 99\n')
        text = ''.join(f'https://example.invalid/repo.git\tprojects/{n}\n'
                       for n in ('checkout', 'directory', 'file', 'link'))
        result = self.clone(text)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual((root / 'file').read_text(), 'keep')
        self.assertTrue((root / 'link').is_symlink())
        self.assertTrue((root / 'checkout' / '.git').is_dir())

    def test_clone_manifest_https_and_unset_remote(self):
        self.stub('git', 'printf "%s\\n" "$@" >> "$CALLS"\nmkdir -p "${@: -1}/.git"\n')
        result = self.clone('# url\tpath\n-\tconfig/dotfiles\ngit@github.com:owner/repo.git\tprojects/repo\n', '--https')
        self.assertEqual(result.returncode, 0, result.stderr)
        calls = (self.work / 'calls').read_text()
        self.assertIn('https://github.com/owner/repo.git', calls)
        self.assertNotIn(str(self.home / 'config/dotfiles'), calls)
        self.assertFalse((self.home / 'config/dotfiles').exists())

    def test_clone_rejects_escaping_manifest_before_any_clone(self):
        self.stub('git', 'touch "$CALLS"\n')
        for target in ('../escape', '/tmp/escape', 'projects/../escape', 'projects//bad'):
            result = self.clone(f'https://example.invalid/repo.git\t{target}\n')
            self.assertNotEqual(result.returncode, 0)
        self.assertFalse((self.work / 'calls').exists())

    def test_clone_refuses_symlink_parent(self):
        (self.home / 'projects').symlink_to(self.work)
        self.stub('git', 'touch "$CALLS"\n')
        result = self.clone('https://example.invalid/repo.git\tprojects/new\n')
        self.assertNotEqual(result.returncode, 0)
        self.assertFalse((self.work / 'calls').exists())

    def test_clone_bad_args_no_writes(self):
        result = self.run_helper('clone-repos', '--unknown')
        self.assertEqual(result.returncode, 2)
        self.assertEqual(list(self.home.iterdir()), [])

    def test_remove_silence_preserves_existing_output_and_defaults(self):
        source = self.work / 'clip.mov'
        source.write_bytes(b'sample')
        (self.work / 'clip-nosilence.mov').write_bytes(b'keep')
        self.stub('auto-editor', 'printf "%s\\n" "$@" > "$CALLS"\n')
        result = self.run_helper('remove-silence', str(source), '--margin', '1sec,1sec')
        self.assertEqual(result.returncode, 0, result.stderr)
        calls = (self.work / 'calls').read_text()
        self.assertIn('clip-nosilence (1).mov', calls)
        self.assertIn('audio:threshold=0.001,stream=all', calls)
        self.assertTrue(calls.endswith('--margin\n1sec,1sec\n'))
        self.assertEqual((self.work / 'clip-nosilence.mov').read_bytes(), b'keep')

    def test_statusline_empty_fields_and_token_total(self):
        data = {'model': {'display_name': 'Model (1M context)'},
                'context_window': {'current_usage': {'input_tokens': 1200,
                                                     'cache_read_input_tokens': 800}}}
        result = subprocess.run([str(ROOT / 'config/claude/statusline.sh')],
                                input=json.dumps(data), env=self.env,
                                capture_output=True, text=True)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout, 'Model │ ctx 2.0K')

    def test_herdr_wrapper_scopes_path_and_preserves_arguments(self):
        self.stub('herdr', 'printf "%s\\n" "$PATH" "$HERDR_BIN_PATH" "$@" > "$CALLS"\n')
        self.env['XDG_DATA_HOME'] = str(self.work / 'data')
        scoped = self.work / 'data/dotfiles/herdr-notify'
        scoped.mkdir(parents=True)
        (scoped / 'notify-send').symlink_to(ROOT / 'bin/herdr-notify-send')
        result = self.run_helper('herdr-with-notify', 'tab', 'space name')
        self.assertEqual(result.returncode, 0, result.stderr)
        lines = (self.work / 'calls').read_text().splitlines()
        self.assertTrue(lines[0].startswith(str(scoped) + ':'))
        self.assertEqual(lines[1], str(self.mock / 'herdr'))
        self.assertEqual(lines[-2:], ['tab', 'space name'])
        self.assertFalse(self.env['PATH'].startswith(str(scoped)))

    def notify_fixture(self):
        self.stub('hyprctl', 'printf "%s\\n" "$*" >> "$CALLS"\n')
        self.stub('notify-real', 'printf "%s\\n" "$@" >> "$CALLS"\nprintf "default\\n"\n')
        script = self.work / 'notify-send'
        text = (ROOT / 'bin/herdr-notify-send').read_text()
        script.write_text(text.replace('REAL=/usr/bin/notify-send', f'REAL="{self.mock / "notify-real"}"'))
        script.chmod(0o755)
        return script

    def test_notify_unrelated_message_passes_through(self):
        script = self.notify_fixture()
        result = subprocess.run([str(script), '--', 'Title', 'Ordinary body'],
                                env=self.env, capture_output=True, text=True)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual((self.work / 'calls').read_text().splitlines(),
                         ['--', 'Title', 'Ordinary body'])

    def test_notify_herdr_message_detaches_with_workspace_and_tab(self):
        script = self.notify_fixture()
        self.stub('setsid', 'printf "%s\\n" "$@" > "$CALLS"\n')
        result = subprocess.run([str(script), '--', 'Title', 'Project · 2 · Agent'],
                                env=self.env, capture_output=True, text=True)
        self.assertEqual(result.returncode, 0, result.stderr)
        args = (self.work / 'calls').read_text().splitlines()
        self.assertEqual(args[-5:], ['--herdr-await-action', 'Title', 'Project · 2 · Agent', '2', 'Agent'])

    def test_notify_action_resolves_ids_and_focuses_tab(self):
        script = self.notify_fixture()
        self.stub('herdr', '''if [[ "$*" == 'workspace list' ]]; then
  printf '%s\\n' '{"result":{"workspaces":[{"number":2,"workspace_id":"ws-id"}]}}'
elif [[ "$*" == 'tab list --workspace ws-id' ]]; then
  printf '%s\\n' '{"result":{"tabs":[{"label":"Agent","tab_id":"tab-id"}]}}'
else
  printf '%s\\n' "$*" >> "$CALLS"
fi
''')
        result = subprocess.run([str(script), '--herdr-await-action', 'Title', 'Project · 2 · Agent', '2', 'Agent'],
                                env=self.env, capture_output=True, text=True)
        self.assertEqual(result.returncode, 0, result.stderr)
        calls = (self.work / 'calls').read_text()
        self.assertIn('workspace focus ws-id', calls)
        self.assertIn('tab focus tab-id', calls)

    def test_secret_guard_redacts_and_detects_fixtures(self):
        import importlib.util
        spec = importlib.util.spec_from_file_location('secret_guard', ROOT / 'scripts/secret_scan.py')
        module = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(module)
        token = 'gh' + 'p_' + 'X' * 36
        fixture = self.work / 'sample.txt'
        fixture.write_text(token)
        count, hits = module.findings(self.work)
        self.assertGreater(count, 0)
        self.assertTrue(any(rule == 'github-token' for _, _, rule in hits))
        self.assertNotIn(token, repr(hits))

    def test_ytmusic_help_offline_without_dependency_install(self):
        result = subprocess.run(['python3', str(ROOT / 'bin/ytmusic-sync'), '--help'],
                                env=self.env, capture_output=True, text=True)
        self.assertEqual(result.returncode, 0, result.stderr)
        for flag in ('--dry-run', '--prune', '--relink', '--no-download'):
            self.assertIn(flag, result.stdout)


if __name__ == '__main__':
    unittest.main()
