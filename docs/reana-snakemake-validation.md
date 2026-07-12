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

## Local workarounds considered

The workflow could avoid `snakemake.utils.validate()` and perform custom Draft 7
validation directly. This was not adopted because it would replace the standard
Snakemake idiom with project-specific validation code and conceal an invalid
REANA prerelease dependency combination.
