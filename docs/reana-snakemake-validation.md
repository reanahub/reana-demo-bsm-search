# REANA Snakemake 9 configuration validation

## Status

As of 2026-07-12, local validation with the REANA 0.95 prerelease stack fails
when a Snakemake 9 workflow calls `snakemake.utils.validate()`:

- `reana-client==0.95.0a5`
- `reana-commons==0.95.0a21`
- `snakemake==9.22.0` on Python 3.11 or newer
- `jsonschema==3.2.0`

The workflow itself passes `snakemake --lint` and `snakemake --dry-run` in its
Pixi environment with Snakemake 9.

The call to `snakemake.utils.validate()` is therefore temporarily disabled in
the Snakefile. The schema remains in the repository both as documentation and so
that standard validation can be restored when the REANA dependency conflict is
resolved.

## Reproduction

Install the prerelease client and validate this repository:

```console
$ pip install --pre "reana-client==0.95.0a5"
$ reana-client --loglevel DEBUG validate
```

Validation fails while loading the Snakefile with:

```text
ImportError: cannot import name 'Draft202012Validator' from 'jsonschema'
```

## Cause

Snakemake 9.22 imports `Draft202012Validator` from `jsonschema` unconditionally
inside `snakemake.utils.validate()`. It also uses the separate `referencing`
package introduced by newer `jsonschema` releases.

At the same time, `reana-commons 0.95.0a21` constrains `jsonschema` to versions
older than 4 because of compatibility requirements from Bravado and Yadage.
Those constraints permit `jsonschema 3.2.0`, which does not provide
`Draft202012Validator`.

Changing this workflow's schema from Draft 2020-12 to Draft 7 does not avoid the
failure: Snakemake imports and instantiates `Draft202012Validator` before it
examines the schema's declared dialect.

## Upstream action

This should be reported to
[`reanahub/reana-commons`](https://github.com/reanahub/reana-commons/issues),
because the REANA 0.95 dependency set selects Snakemake 9 together with an
incompatible `jsonschema` version. No matching existing issue was found when
this note was written.

A useful regression test would load a minimal Snakemake 9 workflow that calls
`snakemake.utils.validate()` using the complete `reana-commons[snakemake]`
environment.

Possible upstream solutions include isolating Snakemake validation from the
Bravado/Yadage dependency set, or updating those dependencies so that REANA can
require a sufficiently recent `jsonschema`. Snakemake should also declare an
appropriate minimum `jsonschema` version in its own package metadata.

Suggested issue title:

> Snakemake 9 config validation fails with the pinned jsonschema version

Once an upstream issue exists, add its link to this document.

## Current workflow workaround

The workflow avoids calling `snakemake.utils.validate()` on REANA. It does not
replace it with custom Draft 7 validation, because that would replace the
standard Snakemake idiom with project-specific validation code and conceal the
invalid REANA prerelease dependency combination.

REANA's Snakemake 9 remote executor also currently submits each rule's raw
shell command without first creating the parent directories of its outputs and
logs. The Snakefile temporarily wraps shell commands with directory preparation
in `shell_with_directories()`. This should be removed when the executor performs
Snakemake's normal pre-job directory preparation.

This requires a fix in
[`reanahub/reana-workflow-engine-snakemake`](https://github.com/reanahub/reana-workflow-engine-snakemake).
A minimal remote rule fails before executing its command with, for example:

```text
bash: line 2: logs/generate/mc2/0.log: No such file or directory
```

Suggested issue title:

> Remote executor does not prepare output and log parent directories

With the call removed, REANA QA successfully parses the Snakefile and builds the
complete 63-job DAG. The standard prerelease client still cannot submit the
workflow directly because the REANA Snakemake loader includes Python callables
from dynamic rule parameters in the JSON request. A one-off submission test
replaced those callables only in the client-generated metadata; the workflow
engine continued to execute the original Snakefile. This serialization problem
is separate from the `jsonschema` dependency conflict and should be fixed in
REANA's Snakemake integration.

On 2026-07-12, the complete workflow ran successfully on REANA QA as
`reana-demo-bsm-snakemake-20260712-133953.3`, using `reana-client==0.95.0a5`
and REANA server `0.95.0a6`. All 62 executable jobs finished, and the resulting
prefit and postfit PDFs and HEPData ZIP archive were downloaded and verified.
