"""Muninで必要な参照APIだけを許可し、認証情報を返さない。"""
import http.client
import json
import re
import socket
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from urllib.parse import parse_qs, urlsplit


class DockerConnection(http.client.HTTPConnection):
    def connect(self):
        self.sock = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
        self.sock.settimeout(30)
        self.sock.connect('/var/run/docker.sock')


def allowed(path):
    url = urlsplit(path)
    route = re.sub(r'^/v[0-9]+\.[0-9]+', '', url.path)
    if route in ('/_ping', '/version', '/containers/json', '/images/json', '/volumes', '/system/df'):
        return True
    if re.fullmatch(r'/containers/[a-zA-Z0-9_.-]+/json', route):
        return True
    if re.fullmatch(r'/containers/[a-zA-Z0-9_.-]+/stats', route):
        return parse_qs(url.query).get('stream') == ['False'] or parse_qs(url.query).get('stream') == ['false'] or parse_qs(url.query).get('stream') == ['0']
    return bool(re.fullmatch(r'/images/[a-zA-Z0-9_:.-]+/json', route))


def sanitize(data):
    # 詳細表示に必要な識別情報と稼働状態のみを残す。
    if isinstance(data, dict) and 'Config' in data and 'State' in data:
        result = {k: data[k] for k in ('Id', 'Name', 'Created', 'Image') if k in data}
        result['State'] = {k: v for k, v in data['State'].items() if k in ('Status', 'Running', 'Paused', 'Restarting', 'OOMKilled', 'Dead', 'ExitCode', 'StartedAt', 'FinishedAt')}
        if 'Health' in data['State']:
            result['State']['Health'] = {'Status': data['State']['Health'].get('Status', '')}
        return result
    if isinstance(data, dict):
        return {k: ({} if k == 'Labels' else sanitize(v)) for k, v in data.items() if k not in ('Env', 'Cmd', 'Command', 'Args', 'Options', 'Mounts', 'Mountpoint', 'GraphDriver', 'ContainerConfig', 'Config', 'Status')}
    if isinstance(data, list):
        return [sanitize(v) for v in data]
    return data


class Handler(BaseHTTPRequestHandler):
    def log_message(self, *args):
        pass

    def do_GET(self):
        if not allowed(self.path):
            self.send_error(403)
            return
        conn = DockerConnection('localhost', timeout=30)
        try:
            conn.request('GET', self.path)
            response = conn.getresponse()
            body = response.read()
            content_type = response.getheader('Content-Type', 'application/json')
            if response.status >= 400:
                self.send_error(502)
                return
            if 'application/json' in content_type:
                body = json.dumps(sanitize(json.loads(body))).encode()
            self.send_response(response.status)
            self.send_header('Content-Type', content_type)
            self.send_header('Content-Length', str(len(body)))
            self.end_headers()
            self.wfile.write(body)
        except (OSError, ValueError, http.client.HTTPException):
            self.send_error(502)
        finally:
            conn.close()

    def do_POST(self):
        self.send_error(403)

    do_PUT = do_POST
    do_DELETE = do_POST
    do_PATCH = do_POST


if __name__ == '__main__':
    ThreadingHTTPServer(('0.0.0.0', 2375), Handler).serve_forever()
