---
name: karate
description: Write, run, and triage Karate API and integration tests from `.feature` files, using the Coroboros karate image or GitLab component when CI is in scope. Use for REST, GraphQL, WebSocket, contract tests from an OpenAPI spec, smoke flows, mocked downstreams, tag-filtered runs, parallel runs, and report triage. Do not use for single-function unit tests, API design, Dockerfile review, or shell linting.
---

# karate

Authors and runs API/integration tests as Karate `.feature` files, then reads the
report into a verdict. Karate supplies HTTP/GraphQL/WebSocket clients,
schema-aware `match` assertions, and a built-in mock server from one fat jar.
This skill decides what to assert, how to run it, and what a failure means.

DSL reference (consult for exact syntax rather than guessing): https://github.com/karatelabs/karate

## Write

A `.feature` file is one or more `Scenario`s. Keep each scenario to one behaviour and
share setup in `Background`. The shape of an HTTP test:

```
Feature: orders API

  Background:
    * url baseUrl

  Scenario: create returns the order with a server id
    Given path 'orders'
    And request { item: 'widget', qty: 2 }
    When method post
    Then status 201
    And match response == { id: '#uuid', item: 'widget', qty: 2, createdAt: '#string' }
```

What earns a test its keep:
- **Assert shape, not just status.** `match` with fuzzy markers (`#string`, `#number`,
  `#uuid`, `#regex(...)`, `#? _ > 0`, `#[]` for arrays, `##null` for optional) pins the
  contract without hard-coding volatile values. `match … contains { … }` checks a subset.
- **Factor reuse with `call` / `callonce`** — auth, a created fixture, shared headers live in
  their own feature and are called from others; `callonce` runs it a single time across scenarios.
- **Data-drive with `Scenario Outline` + `Examples:`** when one flow varies by input — a table
  of cases instead of copy-pasted scenarios.
- **Mock a dependency** the service under test calls, so the test is hermetic: run a mock
  feature with `karate -m mock.feature -p 8080` and point the service at `localhost:8080`.

Prefer a few high-signal scenarios — happy path, the contract, and the failure modes that
matter — over exhaustive permutations.

## Run

The published image is the runner. With Docker, from the project root:

```sh
docker run --rm \
  -v "$PWD/features:/karate/features" \
  -v "$PWD/target:/karate/target" \
  registry.gitlab.com/coroboros/infrastructure/karate:<tag>
```

In GitLab CI, prefer the component — one include runs the suite and publishes the
HTML report as a job artifact:

```yaml
include:
  - component: gitlab.com/coroboros/infrastructure/karate/karate@<version>
    inputs:
      feature_path: features
      parallel: 4
      tags: "@smoke,~@wip"
```

Flags forwarded to the runner: `-T <n>` parallel features, `-t @tag` / `-t ~@tag` to select
or exclude by tag, `-e <env>` to set `karate.env`, `-o <dir>` for output. Karate exits
non-zero when any scenario fails — that is the gate; a non-zero exit is real, never wave it
through as flaky without reading why.

## Analyze

Read the HTML report (`karate-summary.html`) and report a triage, not a dump:

1. **Lead with the verdict** — N passed, M failed, where the failures cluster.
2. **Name each failure's cause** from the report: a `match` mismatch (the report shows
   expected vs actual path-by-path — the fastest signal), a wrong `status`, a connection
   error (target down or wrong `url`), or a schema marker that didn't hold. Cite feature + line.
3. **Give the fix** — correct the assertion if the test was wrong, or report the API defect if
   the response was. A `match` failure is one or the other; say which.
4. **Flaky vs real** — a timeout or connection reset is environment, not a code defect; a
   deterministic `match` / `status` failure is real. Don't retry past a real failure.

Keep it short and decision-oriented. The report holds the data; the judgment is the work.
