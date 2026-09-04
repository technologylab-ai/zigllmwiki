"""Publication-boundary regressions for local review-packet consumption."""
from copy import deepcopy
from argparse import Namespace
import json
import os
from pathlib import Path
import subprocess
import tempfile
import unittest
from unittest.mock import Mock, patch

from tools.curate_review import (PACKET_FILES, REPOSITORY, WORKFLOW, ReviewError,
                                 allowed_path, consume, execute, stage_changes, validate_audit_artifacts,
                                 validate_changes, validate_packet, validate_run)


class CurateReviewTests(unittest.TestCase):
    def metadata(self):
        return {'path': WORKFLOW, 'head_repository': {'full_name': REPOSITORY},
                'head_branch': 'main', 'event': 'schedule', 'status': 'completed',
                'conclusion': 'success', 'head_sha': 'a' * 40, 'id': 123, 'run_attempt': 2}

    def test_packet_origin_and_revision_must_match(self):
        metadata = self.metadata()
        self.assertEqual(validate_run(metadata, 'a' * 40), (123, 2))
        for field, value in [('path', '.github/workflows/other.yml'),
                             ('head_repository', {'full_name': 'someone/fork'}),
                             ('head_branch', 'feature'), ('event', 'pull_request'),
                             ('status', 'in_progress'), ('conclusion', 'failure'),
                             ('head_sha', 'b' * 40), ('id', True), ('run_attempt', 0)]:
            with self.subTest(field=field):
                altered = deepcopy(metadata)
                altered[field] = value
                with self.assertRaises(ReviewError):
                    validate_run(altered, 'a' * 40)

    def test_curation_cannot_change_executable_or_immutable_inputs(self):
        for name in ['wiki/cancellation.md', 'index.md', 'log.md', 'sources/new.md',
                     'reports/new-review.md']:
            self.assertTrue(allowed_path(name, False), name)
        for name in ['AGENTS.md', '.zig-version', 'build.zig', 'tools/wiki.py',
                     'proofs/new.zig', '.github/workflows/wiki-review.yml',
                     '../wiki/escape.md', '/wiki/escape.md', 'wiki/subdir/new.md',
                     'wiki/..\\escape.md']:
            self.assertFalse(allowed_path(name, False), name)
        self.assertFalse(allowed_path('sources/existing.md', True))
        self.assertFalse(allowed_path('reports/existing.md', True))

    def test_packet_requires_clean_checkout_and_exact_compiler(self):
        with tempfile.TemporaryDirectory() as directory:
            packet = Path(directory)
            for name in PACKET_FILES:
                value = '{"schema_version": 1}' if name.endswith('.json') else ''
                (packet / name).write_text(value)
            for name in ('requested-zig-version.txt', 'actual-zig-version.txt'):
                (packet / name).write_text('0.16.0\n')
            self.assertEqual(len(validate_packet(packet, '0.16.0')), len(PACKET_FILES))
            (packet / 'repository-status.txt').write_text(' M wiki/cancellation.md\n')
            with self.assertRaises(ReviewError):
                validate_packet(packet, '0.16.0')
            (packet / 'repository-status.txt').write_text('')
            with self.assertRaises(ReviewError):
                validate_packet(packet, '0.16.1')
            (packet / 'untrusted.sh').write_text('do not execute')
            with self.assertRaises(ReviewError):
                validate_packet(packet, '0.16.0')

    def test_git_diff_cannot_rewrite_log_or_delete_note(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            def git(*arguments):
                return subprocess.check_output(['git', *arguments], cwd=root, text=True).strip()
            git('init', '-q')
            git('config', 'user.name', 'Test')
            git('config', 'user.email', 'test@example.invalid')
            git('config', 'core.autocrlf', 'false')
            git('checkout', '-qb', 'curation/test')
            (root / 'wiki').mkdir()
            (root / 'wiki/note.md').write_bytes(b'original\n')
            (root / 'log.md').write_bytes(b'history\n')
            git('add', '.')
            git('commit', '-qm', 'base')
            base = git('rev-parse', 'HEAD')
            (root / 'log.md').write_bytes(b'history\nappended\n')
            self.assertEqual(validate_changes(root, base, 'curation/test'), ['log.md'])
            (root / 'log.md').write_bytes(b'rewritten\n')
            with self.assertRaises(ReviewError):
                validate_changes(root, base, 'curation/test')
            (root / 'log.md').write_bytes(b'history\r\nappended\r\n')
            with self.assertRaises(ReviewError):
                validate_changes(root, base, 'curation/test')
            (root / 'log.md').write_bytes(b'history\n')
            (root / 'wiki/note.md').unlink()
            with self.assertRaises(ReviewError):
                validate_changes(root, base, 'curation/test')

    def test_named_report_and_log_are_required(self):
        report = 'reports/curation-review-123-2.md'
        validate_audit_artifacts(['log.md', report], 123, 2)
        for changed in [[], ['wiki/note.md'], [report], ['log.md'],
                        ['log.md', 'reports/curation-review-123-1.md']]:
            with self.subTest(changed=changed), self.assertRaises(ReviewError):
                validate_audit_artifacts(changed, 123, 2)

    def test_publication_rebuilds_index_from_verified_worktree(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            def git(*arguments):
                return subprocess.check_output(['git', *arguments], cwd=root, text=True).strip()
            git('init', '-q')
            git('config', 'user.name', 'Test')
            git('config', 'user.email', 'test@example.invalid')
            git('config', 'core.autocrlf', 'false')
            git('checkout', '-qb', 'curation/test')
            (root / 'wiki').mkdir()
            (root / 'tools').mkdir()
            note = root / 'wiki/note.md'
            tool = root / 'tools/trusted.py'
            note.write_bytes(b'original\n')
            tool.write_bytes(b'trusted\n')
            git('add', '.')
            git('commit', '-qm', 'base')
            base = git('rev-parse', 'HEAD')
            # Staged content can differ from both HEAD and the final worktree.
            tool.write_bytes(b'forbidden staged code\n')
            git('add', 'tools/trusted.py')
            tool.write_bytes(b'trusted\n')
            note.write_bytes(b'reviewed change\n')
            changed = validate_changes(root, base, 'curation/test')
            self.assertEqual(changed, ['wiki/note.md'])
            content = {'wiki/note.md': note.read_bytes()}
            stage_changes(root, base, 'curation/test', changed, content)
            self.assertEqual(git('diff', '--cached', '--name-only'), 'wiki/note.md')
            self.assertEqual(git('show', ':tools/trusted.py'), 'trusted')
            # Content changing after verification cannot be staged.
            note.write_bytes(b'unreviewed edit\n')
            with self.assertRaises(ReviewError):
                stage_changes(root, base, 'curation/test', changed, content)
            if os.name == 'posix':
                note.write_bytes(content['wiki/note.md'])
                git('config', 'core.filemode', 'true')
                note.chmod(0o755)
                with self.assertRaises(ReviewError):
                    stage_changes(root, base, 'curation/test', changed, content)

    def test_partial_publication_records_honest_recovery_state(self):
        for failing_command, expected in [('push', 'push-outcome-unknown'),
                                          ('pr', 'branch-pushed-pr-pending')]:
            with self.subTest(failing_command=failing_command), \
                    tempfile.TemporaryDirectory() as directory:
                root = Path(directory)
                report = 'reports/curation-review-123-2.md'
                changed = ['log.md', report]
                def fake_run(command, **kwargs):
                    if command[:2] == ['git', 'clone']:
                        checkout = Path(command[-1])
                        checkout.mkdir()
                        (checkout / '.zig-version').write_text('0.16.0\n')
                        (checkout / 'reports').mkdir()
                        (checkout / report).write_text('reviewed evidence\n')
                        (checkout / 'log.md').write_text('history\nreview\n')
                    if command == ['git', 'rev-parse', 'origin/main']:
                        return 'a' * 40
                    if command == ['git', 'rev-parse', 'HEAD']:
                        return 'b' * 40
                    if command[:3] == ['gh', 'pr', 'list']:
                        return '[]'
                    if command[:2] == ['git', 'ls-remote']:
                        return 'a' * 40 + '\trefs/heads/main\n'
                    if command == ['zig', 'version']:
                        return '0.16.0\n'
                    if command == ['codex', '--version']:
                        return 'codex fixture\n'
                    if (command[:2] == ['git', 'push'] and failing_command == 'push'
                            or command[:3] == ['gh', 'pr', 'create']):
                        raise ReviewError('simulated publication failure')
                    return ''
                args = Namespace(latest=False, run_id=123, state_dir=root,
                                 timeout_seconds=60, publish=True)
                with patch('tools.curate_review.run', side_effect=fake_run), \
                        patch('tools.curate_review.github_json', return_value=self.metadata()), \
                        patch('tools.curate_review.validate_packet', return_value={}), \
                        patch('tools.curate_review.validate_changes', return_value=changed), \
                        patch('tools.curate_review.stage_changes'), patch('builtins.print'):
                    with self.assertRaises(ReviewError):
                        consume(args)
                result = json.loads((root / 'review-123-2/result.json').read_text())
                self.assertEqual(result['status'], expected)
                self.assertEqual(result['commit'], 'b' * 40)
                self.assertIn('recovery', result)
                self.assertEqual(result['draft_pr_command'][:3], ['gh', 'pr', 'create'])

    def test_latest_without_current_packet_waits_without_agent_or_state(self):
        args = Namespace(latest=True, run_id=None)
        def fake_run(command, **kwargs):
            if command == ['git', 'fetch', 'origin', 'main']:
                return ''
            if command == ['git', 'rev-parse', 'origin/main']:
                return 'a' * 40
            self.fail(f'unexpected operation while waiting: {command}')
        stale = self.metadata()
        stale['head_sha'] = 'b' * 40
        with patch('tools.curate_review.run', side_effect=fake_run), \
                patch('tools.curate_review.github_json', return_value={'workflow_runs': [stale]}):
            result = consume(args)
        self.assertEqual(result['status'], 'waiting-for-current-review')
        self.assertFalse(result['agent_started'])
        self.assertEqual(result['base_sha'], 'a' * 40)

    def test_timeout_and_interrupt_reap_owned_child(self):
        for error in [subprocess.TimeoutExpired('fixture', 1), KeyboardInterrupt()]:
            with self.subTest(error=type(error).__name__):
                child = Mock(pid=12345)
                child.communicate.side_effect = [error, ('', '')]
                with patch('tools.curate_review.subprocess.Popen', return_value=child), \
                        patch('tools.curate_review.os.killpg', create=True) as kill_group:
                    with self.assertRaises(type(error)):
                        execute(['fixture'], cwd=Path.cwd(), environment={}, timeout=1,
                                input_text=None, output=subprocess.PIPE)
                    self.assertEqual(child.communicate.call_count, 2)
                    if os.name == 'posix':
                        kill_group.assert_called_once()
                    else:
                        child.kill.assert_called_once()


if __name__ == '__main__':
    unittest.main()
