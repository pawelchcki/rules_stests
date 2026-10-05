"""Record the same RealWorld HTTP workload using one pinned Ruby app."""

import argparse
import http.client
import json
from pathlib import Path
import socket
import subprocess
import tempfile
import time
from urllib.parse import quote


def record(port):
    transcript = []

    def request(label, method, path, status, body=None, token=None, raw=None):
        headers = {"X-Parity-Tick": str(len(transcript))}
        if token:
            headers["Authorization"] = "Token " + token
        if body is not None or raw is not None:
            headers["Content-Type"] = "application/json"
        data = raw
        if raw is None and body is not None:
            data = json.dumps(body, ensure_ascii=False).encode("utf-8")
        connection = http.client.HTTPConnection("127.0.0.1", port, timeout=10)
        try:
            connection.request(method, "/api" + path, body=data, headers=headers)
            response = connection.getresponse()
            payload = response.read()
            try:
                value = json.loads(payload) if payload else None
            except ValueError as error:
                raise AssertionError(f"{label}: HTTP {response.status} returned non-JSON data: {payload[:500]!r}") from error
            observed = {"status": response.status, "contentType": response.getheader("Content-Type"), "body": value}
        finally:
            connection.close()
        if observed["status"] != status:
            raise AssertionError(f"{label}: expected HTTP {status}, got {observed}")
        transcript.append({"case": label, "response": observed})
        return value

    def register(name, email):
        return request("register " + name, "POST", "/users", 201, {"user": {"username": name, "email": email, "password": "password123"}})["user"]["token"]

    request("empty tags", "GET", "/tags", 200)
    request("empty articles", "GET", "/articles", 200)
    request("missing token", "GET", "/user", 401)
    request("invalid token", "GET", "/user", 401, token="invalid")
    request("missing registration", "POST", "/users", 422, {})
    request("invalid json", "POST", "/users", 400, raw=b"{")
    request("blank registration", "POST", "/users", 422, {"user": {"username": "", "email": "", "password": ""}})
    author = register("author", "AUTHOR@EXAMPLE.COM")
    reader = register("reader", "reader@example.com")
    stranger = register("stranger", "stranger@example.com")
    unicode_name = "josé_日本"
    unicode_author = register(unicode_name, "unicode@example.com")
    request("unicode profile", "GET", "/profiles/" + quote(unicode_name), 200)
    request("follow unicode profile", "POST", "/profiles/" + quote(unicode_name) + "/follow", 200, token=reader)
    request("duplicate user", "POST", "/users", 409, {"user": {"username": "author", "email": "new@example.com", "password": "password123"}})
    request("invalid login", "POST", "/users/login", 401, {"user": {"email": "author@example.com", "password": "wrong"}})
    request("login", "POST", "/users/login", 200, {"user": {"email": "author@example.com", "password": "password123"}})
    request("current user", "GET", "/user", 200, token=author)
    request("update profile", "PUT", "/user", 200, {"user": {"bio": "café 日本語 🦊", "image": "https://example.com/avatar.png"}}, author)
    request("profile anonymous", "GET", "/profiles/author", 200)
    request("follow", "POST", "/profiles/author/follow", 200, token=reader)
    request("follow repeated", "POST", "/profiles/author/follow", 200, token=reader)
    request("profile followed", "GET", "/profiles/author", 200, token=reader)
    request("empty feed", "GET", "/articles/feed", 200, token=reader)
    request("article unauthenticated", "POST", "/articles", 401, {"article": {"title": "Hello"}})
    request("blank article", "POST", "/articles", 422, {"article": {"title": "", "description": "", "body": ""}}, author)
    slugs = []
    for index, title in enumerate(["Hello World", "Hello World", "Café déjà vu", "Cafe\u0301 de\u0301ja\u0300 vu", "Ｆｕｌｌ Ｗｉｄｔｈ", "日本語"]):
        value = request(f"create article {index}", "POST", "/articles", 201, {"article": {"title": title, "description": "Shared description", "body": "UTF-8: café 日本語 🦊", "tagList": ["ruby", "sqlite", "ruby", "日本語"]}}, author)
        slugs.append(value["article"]["slug"])
    request("unicode author article", "POST", "/articles", 201, {"article": {"title": "Unicode Author", "description": "Unicode author", "body": "café 日本語 🦊"}}, unicode_author)
    request("articles unicode author", "GET", "/articles?author=" + quote(unicode_name), 200)
    slug = slugs[0]
    request("article anonymous", "GET", "/articles/" + slug, 200)
    request("articles all", "GET", "/articles", 200)
    for query in ["limit=2&offset=1", "limit=0", "limit=-1&offset=-2", "limit=bad&offset=bad", "author=author", "author=reader", "tag=ruby", "tag=missing"]:
        request("articles " + query, "GET", "/articles?" + query, 200)
    request("tags populated", "GET", "/tags", 200)
    request("favorite missing token", "POST", "/articles/" + slug + "/favorite", 401)
    request("favorite", "POST", "/articles/" + slug + "/favorite", 200, token=reader)
    request("favorite repeated", "POST", "/articles/" + slug + "/favorite", 200, token=reader)
    request("favorite other user", "POST", "/articles/" + slug + "/favorite", 200, token=stranger)
    request("article favorited", "GET", "/articles/" + slug, 200, token=reader)
    request("articles favorited", "GET", "/articles?favorited=reader", 200)
    request("feed followed", "GET", "/articles/feed?limit=2&offset=1", 200, token=reader)
    request("update forbidden", "PUT", "/articles/" + slug, 403, {"article": {"title": "Forbidden"}}, reader)
    value = request("update article", "PUT", "/articles/" + slug, 200, {"article": {"title": "Renamed Article", "body": "Updated 日本語", "tagList": ["updated", "ruby"]}}, author)
    renamed = value["article"]["slug"]
    request("old slug missing", "GET", "/articles/" + slug, 404)
    request("updated article", "GET", "/articles/" + renamed, 200, token=reader)
    request("comments empty", "GET", "/articles/" + renamed + "/comments", 200)
    value = request("create comment", "POST", "/articles/" + renamed + "/comments", 201, {"comment": {"body": "Comment café 日本語 🦊"}}, reader)
    comment = str(value["comment"]["id"])
    request("comments list", "GET", "/articles/" + renamed + "/comments", 200, token=author)
    request("comment delete forbidden", "DELETE", "/articles/" + renamed + "/comments/" + comment, 403, token=author)
    request("comment delete", "DELETE", "/articles/" + renamed + "/comments/" + comment, 204, token=reader)
    request("comment missing", "DELETE", "/articles/" + renamed + "/comments/" + comment, 404, token=reader)
    request("comment recreate", "POST", "/articles/" + renamed + "/comments", 201, {"comment": {"body": "A second comment"}}, reader)
    request("comments after recreate", "GET", "/articles/" + renamed + "/comments", 200)
    request("unfavorite", "DELETE", "/articles/" + renamed + "/favorite", 200, token=reader)
    request("unfavorite repeated", "DELETE", "/articles/" + renamed + "/favorite", 200, token=reader)
    request("unfollow", "DELETE", "/profiles/author/follow", 200, token=reader)
    request("unfollow repeated", "DELETE", "/profiles/author/follow", 200, token=reader)
    request("feed unfollowed", "GET", "/articles/feed", 200, token=reader)
    request("delete forbidden", "DELETE", "/articles/" + renamed, 403, token=reader)
    request("delete article", "DELETE", "/articles/" + renamed, 204, token=author)
    request("deleted article", "GET", "/articles/" + renamed, 404)
    request("articles remaining", "GET", "/articles", 200)
    request("tags remaining", "GET", "/tags", 200)
    request("profile missing", "GET", "/profiles/missing", 404)
    request("article missing", "GET", "/articles/missing", 404)
    request("clear profile", "PUT", "/user", 200, {"user": {"bio": "", "image": ""}}, author)
    return transcript


def main():
    parser = argparse.ArgumentParser()
    for name in ("output", "app", "runtime", "launcher", "bootstrap"):
        parser.add_argument("--" + name, required=True, type=Path)
    args = parser.parse_args()
    with socket.socket() as reservation:
        reservation.bind(("127.0.0.1", 0))
        port = reservation.getsockname()[1]
    with tempfile.TemporaryDirectory(prefix="ruby-parity-") as temporary:
        environment = {"APP_STATE_DIR": temporary, "LANG": "C.UTF-8"}
        log = Path(temporary) / "server.log"
        with log.open("w+") as output:
            server = subprocess.Popen([
                str(args.launcher.resolve()), "--runtime=ruby", "--instance=parity",
                "--rootfs=" + str(args.app.resolve()), "--ruby-rootfs=" + str(args.runtime.resolve()),
                "--", str(args.bootstrap.resolve()), "--host", "127.0.0.1", "--port", str(port),
            ], env=environment, stdout=output, stderr=output)
            try:
                deadline = time.monotonic() + 15
                while True:
                    if server.poll() is not None:
                        raise RuntimeError("server exited before readiness")
                    try:
                        connection = http.client.HTTPConnection("127.0.0.1", port, timeout=1)
                        connection.request("GET", "/api/tags")
                        response = connection.getresponse()
                        response.read()
                        connection.close()
                        if response.status == 200:
                            break
                    except OSError:
                        pass
                    if time.monotonic() >= deadline:
                        raise TimeoutError("server readiness timed out")
                    time.sleep(0.02)
                transcript = record(port)
                manifest = json.loads((args.app / "opt/app/build-inputs.json").read_text())
                receipt = {"runtime": manifest["runtime"], "responses": transcript}
                args.output.write_text(json.dumps(receipt, ensure_ascii=False, sort_keys=True, indent=2) + "\n")
                print(f"Recorded {len(transcript)} RealWorld responses on Ruby {manifest['runtime']['version']}")
            except BaseException:
                output.flush()
                print("\n".join(log.read_text().splitlines()[-40:]))
                raise
            finally:
                server.terminate()
                try:
                    server.wait(timeout=10)
                except subprocess.TimeoutExpired:
                    server.kill()
                    server.wait()
                    raise RuntimeError("server did not stop cleanly")
                if server.returncode != 0:
                    raise RuntimeError(f"server exited with {server.returncode}: {log.read_text()}")


if __name__ == "__main__":
    main()
