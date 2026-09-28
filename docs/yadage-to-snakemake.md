# Yadage to Snakemake: translation reference

This maps the original Yadage workflow (`workflow/*.yml`, driven by
`reana.yaml`) to the Snakemake port (`Snakefile`, driven by
`reana-snakemake.yaml`). Two tables: general concepts first, then the concrete
stage-by-stage mapping for this specific analysis.

## Concept mapping

| Yadage                                                                                                          | Snakemake                                                                                            | Notes                                                                            |
| --------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------- |
| `stages:` (named list of steps)                                                                                 | `rule <name>:` blocks                                                                                | Same unit of work, different declaration style                                   |
| `scheduler_type: singlestep-stage`                                                                              | a rule with no wildcards                                                                             | Runs exactly once                                                                |
| `scheduler_type: multistep-stage` + `scatter:`                                                                  | a rule with wildcards, fanned out via `expand()` in whatever rule consumes its output                | One job per scattered value either way                                           |
| `scatter: {method: zip, parameters: [a, b]}`                                                                    | multiple wildcards in one output path, e.g. `{mc}_{shapevar}`                                        | Index-wise pairing becomes wildcard combinations Snakemake resolves itself       |
| `batchsize: N` on a merge stage                                                                                 | not reproduced                                                                                       | See "Where the structure changed" below                                          |
| `dependencies: [stageA, stageB]`                                                                                | nothing explicit; inferred from `input:`/`output:` paths matching                                    | Snakemake builds the DAG from file paths, not a declared list                    |
| `parameters: {stages: X, output: Y}`                                                                            | `input:` referencing another rule's `output:` path, or plain Python values from `PROFILES`/wildcards | Same idea, resolved differently                                                  |
| `workflow: {$ref: sub.yml}` (nested sub-workflow)                                                               | flattened into more rules in the same `Snakefile`                                                    | No nesting; Snakemake's `include:` exists but wasn't needed here                 |
| `step: {$ref: steps.yml#/name}` (shared packtivity template)                                                    | the `shell_cmd()` helper, or duplicated `shell:` text where the command differs per rule             | Sometimes a shared function, sometimes just repetition                           |
| `process.process_type: interpolated-script-cmd` + `script: \|` with `{param}` placeholders                      | `shell:` string with `{wildcards.x}` / `{params.x}` / `{input}` / `{output}`                         | Direct equivalent, same interpolation idea                                       |
| `environment.environment_type: docker-encapsulated` + `image` + `imagetag`                                      | `container: IMG_MAIN` (a `docker://image:tag` string)                                                | Direct equivalent                                                                |
| `publisher.publisher_type: frompar-pub` + `outputmap`                                                           | `output:` declaration                                                                                | The declared output path _is_ the published file; no separate publish step       |
| `publisher.publisher_type: interpolated-pub` + `glob: true` (makews's `{prefix}*combined*model.root`)           | a fixed, explicit output path                                                                        | Our `makews.py` call controls the exact filename, so there's nothing to glob for |
| top-level input files (`inputsm.yml`, `inputsig.yml`, `allmc_input.yml`) feeding Yadage's implicit `init` stage | `PROFILES` dict + `config.get("profile", "full")`                                                    | Same role: initial parameters for the whole run                                  |

## Where the structure changed

The Yadage sub-workflows (`workflow_mc.yml`, `workflow_data.yml`,
`workflow_sig.yml`) select on partially-merged batches and merge again
afterward, controlled by `batchsize`. For example `workflow_mc.yml`'s `merge`
stage has `batchsize: 2` over 4 generated chunks, producing 2 partial merges;
`select_signal` then runs once per partial merge, and `select_signal_merge`
combines the selected outputs back into one file.

The Snakemake port collapses this: `merge_generated` always combines every batch
for a sample into a single file right after generation, and every
`select_*`/`histogram_*` rule downstream runs once on that complete file. Fewer
rules, fewer jobs, same final numbers, since `hadd` and the selection cuts don't
care where the batch boundaries were. This is also why several Yadage stages
below map to "not needed" rather than a named rule.

## Stage-by-stage mapping

### `databkgmc.yml` (top level)

| Yadage stage                        | Snakemake rule                                              |
| ----------------------------------- | ----------------------------------------------------------- |
| `all_bkg_mc`                        | flattened, see `wflow_all_mc.yml` / `workflow_mc.yml` below |
| `data`                              | flattened, see `workflow_data.yml` below                    |
| `signal`                            | flattened, see `workflow_sig.yml` below                     |
| `merge` (step `merge_root_allpars`) | `merge_all`                                                 |
| `makews`                            | `makews`                                                    |
| `plot`                              | `plot`                                                      |
| `hepdata`                           | `hepdata`                                                   |

### `workflow_data.yml`

| Yadage stage           | Snakemake rule                                           |
| ---------------------- | -------------------------------------------------------- |
| `read`                 | `generate` (`sample=data`)                               |
| `merge`                | `merge_generated` (`sample=data`)                        |
| `select_signal`        | `data_select` (`region=signal`)                          |
| `select_signal_merge`  | not needed (`merge_generated` already merged everything) |
| `select_control`       | `data_select` (`region=control`)                         |
| `select_control_merge` | not needed                                               |
| `select_signal_hist`   | `data_hist_signal`                                       |
| `select_control_hist`  | `data_hist_control`                                      |
| `mergeall`             | `data_mergeall`                                          |

### `workflow_sig.yml`

| Yadage stage   | Snakemake rule                                                 |
| -------------- | -------------------------------------------------------------- |
| `read`         | `generate` (`sample=sig`)                                      |
| `merge`        | `merge_generated` (`sample=sig`)                               |
| `select`       | `sig_select`                                                   |
| `select_merge` | not needed                                                     |
| `select_hist`  | `sig_hist`                                                     |
| `hist_merge`   | folded into `sig_hist`'s output (only ever one histogram file) |

### `wflow_all_mc.yml` + `workflow_mc.yml` (once per `mc1`/`mc2` via `{mc}`)

| Yadage stage                                                                           | Snakemake rule                                                               |
| -------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------- |
| `run_mc` (scatters `workflow_mc.yml` over `mc1`/`mc2`)                                 | replaced by the `{mc}` wildcard on every `mc_*` rule                         |
| `workflow_mc.yml: read`                                                                | `generate` (`sample=mc1` / `mc2`)                                            |
| `merge`                                                                                | `merge_generated` (`sample=mc1` / `mc2`)                                     |
| `select_signal` (weight variations)                                                    | `mc_select_weights`                                                          |
| `select_signal_merge`                                                                  | not needed                                                                   |
| `select_signal_hist`                                                                   | `mc_hist_weights`                                                            |
| `mergeweights`                                                                         | folded into `mc_hist_weights`'s single output                                |
| `select_signal_shapevars` (scatters `workflow_select_shape.yml` over shape variations) | replaced by the `{shapevar}` wildcard on `mc_select_shape` / `mc_hist_shape` |
| `mergeshapes`                                                                          | folded into `mc_hist_shape`'s single output                                  |
| `mergeallvars` (in both `wflow_all_mc.yml` and `workflow_mc.yml`)                      | `mc_mergeallvars`                                                            |

### `workflow_select_shape.yml` (instantiated per `{mc}` × `{shapevar}`)

| Yadage stage | Snakemake rule    |
| ------------ | ----------------- |
| `select`     | `mc_select_shape` |
| `merge`      | not needed        |
| `hist`       | `mc_hist_shape`   |

### `steps.yml` (packtivity templates, reused across the stages above)

| Yadage packtivity    | Snakemake equivalent                                                                         |
| -------------------- | -------------------------------------------------------------------------------------------- |
| `generate`           | `generate`'s `shell:`, calling `code/generantuple.py`                                        |
| `select`             | `data_select` / `sig_select`'s `shell:`, calling `code/select.py` with `nominal` only        |
| `select_mc`          | `mc_select_weights` / `mc_select_shape`'s `shell:`, calling `code/select.py` with variations |
| `histogram`          | `data_hist_*` / `sig_hist` / `mc_hist_weights`'s `shell:`, calling `code/histogram.py`       |
| `histogram_shape`    | `mc_hist_shape`'s `shell:`, calling `code/histogram.py` with a name template                 |
| `merge_root`         | every plain `hadd`-based rule (`merge_generated`, `data_mergeall`, `mc_mergeallvars`, ...)   |
| `merge_root_allpars` | `merge_all`                                                                                  |
| `makews`             | `makews`'s `shell:`, calling `code/makews.py`                                                |
| `plot`               | `plot`'s `shell:`, the `hfquickplot` calls                                                   |
| `hepdata`            | `hepdata`'s `shell:`, calling `code/hepdata_export.py` + `zip`                               |

### Input parameter files

| Yadage file                                                     | Snakemake equivalent                                                   |
| --------------------------------------------------------------- | ---------------------------------------------------------------------- |
| `allmc_input.yml` (`mcname`, `mcweight`, `nevents` for mc1/mc2) | `PROFILES[...]["nevents"]["mc1"/"mc2"]`, `PROFILES[...]["mc_weights"]` |
| `inputsig.yml` (signal `nevents`, `mcweight`)                   | `PROFILES[...]["nevents"]["sig"]`, `PROFILES[...]["sig_weight"]`       |
| `inputsm.yml` (data `nevents`)                                  | `PROFILES[...]["nevents"]["data"]`                                     |

The two profiles in `Snakefile` (`full`, `test`) roughly correspond to the
numbers in these three files versus a scaled-down local set.
