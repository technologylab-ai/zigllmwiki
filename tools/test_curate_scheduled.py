"""Host-fallback tests: never launch a second curator after starting remotely."""
from unittest import TestCase, main, mock
from tools import curate_scheduled


class ScheduledCurationTests(TestCase):
    @mock.patch.object(curate_scheduled.subprocess, 'call', return_value=7)
    @mock.patch.object(curate_scheduled.subprocess, 'run')
    def test_remote_failure_is_not_retried_locally(self, probe, invoke):
        probe.return_value.returncode = 0
        with mock.patch.object(curate_scheduled.sys, 'platform', 'linux'), \
             mock.patch.object(curate_scheduled.sys, 'argv', ['curate_scheduled.py']):
            self.assertEqual(curate_scheduled.main(), 7)
        self.assertEqual(invoke.call_count, 1)
        self.assertEqual(invoke.call_args.args[0][0], 'ssh')

    @mock.patch.object(curate_scheduled.subprocess, 'call', return_value=0)
    @mock.patch.object(curate_scheduled.subprocess, 'run', side_effect=OSError('offline'))
    def test_unavailable_mac_falls_back_to_local_consumer(self, probe, invoke):
        with mock.patch.object(curate_scheduled.sys, 'platform', 'linux'), \
             mock.patch.object(curate_scheduled.sys, 'argv', ['curate_scheduled.py']):
            self.assertEqual(curate_scheduled.main(), 0)
        self.assertEqual(invoke.call_count, 1)
        self.assertIn('curate_review.py', invoke.call_args.args[0][1])


if __name__ == '__main__':
    main()
