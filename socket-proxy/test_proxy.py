"""参照APIの許可範囲と認証情報の除去を検証する。"""
import unittest
from proxy import allowed, sanitize


class ProxyTest(unittest.TestCase):
    def test_monitoring_routes(self):
        for path in ('/_ping', '/v1.45/version', '/v1.45/containers/json?all=1', '/containers/app-1/json', '/containers/app-1/stats?stream=False', '/images/sha256:abc/json', '/system/df', '/volumes'):
            self.assertTrue(allowed(path), path)

    def test_unneeded_routes_are_denied(self):
        for path in ('/containers/app-1/archive?path=/', '/containers/app-1/export', '/containers/app-1/logs', '/containers/app-1/stats?stream=true', '/containers/app-1/exec', '/info', '/secrets', '/containers/app-1/../../info'):
            self.assertFalse(allowed(path), path)

    def test_inspect_does_not_expose_credentials(self):
        value = sanitize({'Id': 'abc', 'Name': '/app', 'Created': 'now', 'Image': 'sha256:abc', 'State': {'Status': 'running', 'Health': {'Status': 'healthy', 'Log': [{'Output': '秘密'}]}, 'Error': '秘密'}, 'Config': {'Env': ['PASSWORD=秘密'], 'Cmd': ['秘密']}, 'HostConfig': {'Binds': ['秘密']}})
        self.assertEqual(value['State']['Status'], 'running')
        self.assertNotIn('秘密', str(value))
        self.assertNotIn('Config', value)

    def test_list_and_labels_are_sanitized(self):
        value = sanitize([{'Names': ['/app'], 'Command': '秘密', 'Labels': {'password': '秘密'}, 'Mounts': ['秘密']}])
        self.assertEqual(value[0]['Labels'], {})
        self.assertNotIn('秘密', str(value))


if __name__ == '__main__':
    unittest.main()
