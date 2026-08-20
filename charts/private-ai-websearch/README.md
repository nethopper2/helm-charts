# private-ai-websearch

SearXNG (metasearch) + Crawl4AI (headless-browser fetcher). Deployed as its own release;
consumers such as `nh-rag` point at the two Services by URL.

The chart never creates the credentials Secret. `secretName` must name an existing Secret
holding `SEARXNG_SECRET` and `CRAWL4AI_API_TOKEN`.

## Local testing on minikube

### 1. Start a cluster

Crawl4AI alone requests 2Gi, so the default minikube VM is too small.

```bash
minikube start --profile websearch --memory=8g --cpus=4
kubectl config current-context          # expect "websearch", not a remote cluster
```

### 2. Create the Secret

```bash
kubectl create namespace websearch
kubectl create secret generic websearch-creds -n websearch \
  --from-literal=SEARXNG_SECRET="$(openssl rand -hex 32)" \
  --from-literal=CRAWL4AI_API_TOKEN="$(openssl rand -hex 24)"
```

### 3. Install

```bash
helm install ws charts/private-ai-websearch -n websearch --set secretName=websearch-creds
```

First rollout is slow — the Crawl4AI image ships Playwright and Chromium and is several GB.

```bash
kubectl -n websearch rollout status deploy/ws-private-ai-websearch-searxng  --timeout=10m
kubectl -n websearch rollout status deploy/ws-private-ai-websearch-crawl4ai --timeout=15m
```

A pod stuck in `Pending` is almost always memory. Confirm with
`kubectl -n websearch describe pod <name>`; either give minikube more RAM or lower the
request for local work: `--set crawl4ai.resources.requests.memory=1Gi`.

### 4. Read the Crawl4AI token back out

Every Crawl4AI endpoint except `/health` needs this as a Bearer token.

```bash
# print it
kubectl get secret websearch-creds -n websearch \
  -o jsonpath='{.data.CRAWL4AI_API_TOKEN}' | base64 -d; echo

# or keep it in the shell for the calls below
export TOKEN=$(kubectl get secret websearch-creds -n websearch \
  -o jsonpath='{.data.CRAWL4AI_API_TOKEN}' | base64 -d)
```

Same shape for `SEARXNG_SECRET` if you ever need to check it — but SearXNG uses it
internally for session signing, not for API auth, so no call needs it.

### 5. Port-forward using the real addresses

Map the Service names to localhost and forward the **same** port numbers the Services use.
The in-cluster URL then works verbatim from your laptop, so app config is identical here and
in production. Forwarding `8081:8080` breaks this — the ports must match.

```bash
sudo sh -c 'cat >> /etc/hosts <<EOF
127.0.0.1 ws-private-ai-websearch-searxng ws-private-ai-websearch-searxng.websearch.svc.cluster.local
127.0.0.1 ws-private-ai-websearch-crawl4ai ws-private-ai-websearch-crawl4ai.websearch.svc.cluster.local
EOF'

kubectl -n websearch port-forward svc/ws-private-ai-websearch-searxng  8080:8080 &
kubectl -n websearch port-forward svc/ws-private-ai-websearch-crawl4ai 11235:11235 &
```

`kubefwd` automates this for a whole namespace and cleans up on exit:
`brew install txn2/tap/kubefwd && sudo kubefwd svc -n websearch`.

Remove the `/etc/hosts` lines when you are done — stale entries pointing real Service names
at 127.0.0.1 cause confusing failures later.

If your app runs in a container on your laptop, the host's `/etc/hosts` does not apply inside
it; add `--add-host=ws-private-ai-websearch-searxng:host-gateway` (same for crawl4ai) to
`docker run`, or `extra_hosts` in compose.

### 6. Test both services

```bash
# SearXNG — no auth. 403 means `json` was dropped from search.formats,
# 429 means server.limiter was turned back on.
curl -s 'http://ws-private-ai-websearch-searxng:8080/search?q=kubernetes&format=json' | head -c 400

# Crawl4AI — the only unauthenticated endpoint
curl -s http://ws-private-ai-websearch-crawl4ai:11235/health

# The test that matters: this one actually drives Chromium, and therefore /dev/shm
curl -s -X POST http://ws-private-ai-websearch-crawl4ai:11235/crawl \
  -H "Authorization: Bearer $TOKEN" -H 'Content-Type: application/json' \
  -d '{"urls":["https://example.com"],"crawler_config":{"type":"CrawlerRunConfig","params":{"cache_mode":"bypass"}}}' \
  | head -c 600
```

Then confirm nothing restarted. Both counts should be `0`; a non-zero Crawl4AI count usually
means `crawl4ai.shmSize` is too small for the crawl load, or its memory limit is.

```bash
kubectl -n websearch get pods \
  -o custom-columns=NAME:.metadata.name,READY:.status.containerStatuses[0].ready,RESTARTS:.status.containerStatuses[0].restartCount
```

`http://ws-private-ai-websearch-crawl4ai:11235/docs` serves the live OpenAPI spec for the
pinned image — the authoritative reference for request shapes.

### 7. Clean up

```bash
minikube delete -p websearch
sudo sed -i '' '/private-ai-websearch/d' /etc/hosts
```

## Consuming from an app

| App runs | SEARXNG_URL | CRAWL4AI_URL |
|---|---|---|
| In-cluster, same namespace | `http://ws-private-ai-websearch-searxng:8080` | `http://ws-private-ai-websearch-crawl4ai:11235` |
| In-cluster, other namespace | + `.websearch.svc.cluster.local` | + `.websearch.svc.cluster.local` |
| Laptop, port-forwarded as above | same as in-cluster | same as in-cluster |

The names embed the release name (`ws` above). Pick the release name you will use in
production and stay consistent, or the local/production parity is lost.

For `nh-rag`, set these and it wires both env vars and the token into the api and worker:

```yaml
websearch:
  enabled: true
  secretName: websearch-creds
  searxngUrl: "http://ws-private-ai-websearch-searxng:8080"
  crawl4aiUrl: "http://ws-private-ai-websearch-crawl4ai:11235"
```

### Endpoints

- **SearXNG** — `GET /search?q=<query>&format=json`, returns `results[]` with
  `url` / `title` / `content` (the snippet). No auth.
- **Crawl4AI** — `POST /crawl` with `Authorization: Bearer <CRAWL4AI_API_TOKEN>`; response
  carries `success` plus per-URL `markdown`, `html`, `cleaned_html`, `links`, `metadata`.
  Also `/crawl/stream`, `/html`, `/screenshot`, `/pdf`, `/execute_js`, `/schema`.
