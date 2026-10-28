# ADR-0004: In-flight request deduplication

Status: Accepted

## Context
Several parts of the app can request the same resource at the same time.
Duplicate calls waste data and battery on slow or metered connections.

## Decision
`DeduplicatingHTTPClient` is an actor decorator that shares one in-flight
GET among identical concurrent callers. The key is the full `HTTPRequest`
(URL, method, headers, body, timeout). Each caller waits on its own
continuation, and the shared call is cancelled only when no caller is left.
Compose it outermost: Deduplicating(Retrying(URLSession)), so retries run
once per shared call.

## Alternatives considered
- Response cache: risks stale data and needs invalidation rules.
- Share one `Task` and await `task.value`: a cancelled caller would keep
  waiting until the request finishes.
- Locks or dispatch queues: no compile-time data race safety under Swift 6.
- Deduplicate all methods: identical writes can be intentional.

## Consequences
- Requests differing only in headers or timeout are not merged.
- Callers wait on a shared result; one slow call delays all of them.
- State changes stay in synchronous actor sections to avoid reentrancy bugs.
