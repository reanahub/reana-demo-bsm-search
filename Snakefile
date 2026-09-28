# Snakemake port of workflow/databkgmc.yml (reana-demo-bsm-search)
#
# Local dry-run:   snakemake -np
# Local run:       snakemake --cores 4 --software-deployment-method apptainer
# Quick test run:  snakemake --cores 4 --software-deployment-method apptainer \
#                    --config profile=test
# On REANA:        reana-client validate -f reana-snakemake.yaml && ...
#
# Per-job logs land under logs/<rule>[_<wildcards>].log regardless of what
# REANA's own job-log viewer shows (see shell_cmd() below for why that
# distinction matters).

# ---------------------------------------------------------------------------
# Configuration (full = numbers from databkgmc.yml, test = small local run)
# ---------------------------------------------------------------------------
PROFILES = {
    "full": {
        "batches":  {"data": 5,     "sig": 2,     "mc1": 4,     "mc2": 4},
        "nevents":  {"data": 20000, "sig": 40000, "mc1": 40000, "mc2": 40000},
        "mc_weights": {"mc1": 0.01875, "mc2": 0.0125},
        "sig_weight": 0.0025,
    },
    "test": {
        "batches":  {"data": 10,    "sig": 4,    "mc1": 2,   "mc2": 2},
        "nevents":  {"data": 10000, "sig": 1000, "mc1": 200, "mc2": 200},
        "mc_weights": {"mc1": 0.01875, "mc2": 0.0125},
        "sig_weight": 0.02,
    },
}


def _require_profile_shape(cfg, profile_name):
    """Fail fast on a malformed profile instead of letting a random rule,
    three hours into a run, crash on a missing dict key.
    """
    samples = ("data", "sig", "mc1", "mc2")
    for field in ("batches", "nevents"):
        missing = [s for s in samples if s not in cfg.get(field, {})]
        if missing:
            raise ValueError(f"profile {profile_name!r}: {field} missing entries for {missing}")
    missing_w = [s for s in ("mc1", "mc2") if s not in cfg.get("mc_weights", {})]
    if missing_w:
        raise ValueError(f"profile {profile_name!r}: mc_weights missing entries for {missing_w}")
    if not isinstance(cfg.get("sig_weight"), (int, float)):
        raise ValueError(f"profile {profile_name!r}: sig_weight must be numeric")
    return cfg


PROFILE = config.get("profile", "full")
if PROFILE not in PROFILES:
    raise ValueError(f"unknown profile {PROFILE!r}, choose one of {sorted(PROFILES)}")
CFG = _require_profile_shape(PROFILES[PROFILE], PROFILE)

BATCHES    = CFG["batches"]
NEVENTS    = CFG["nevents"]
MC_WEIGHTS = CFG["mc_weights"]
SIG_WEIGHT = CFG["sig_weight"]

MC_SAMPLES = ["mc1", "mc2"]
QCD_WEIGHT = 0.1875  # 0.2 / 0.8 * 0.75 transfer factor to signal region

WEIGHT_VARIATIONS = "nominal,weight_var1_up,weight_var1_dn"
SHAPE_VARS = ["shape_conv_up", "shape_conv_dn"]

# Reproducibility: deterministic, per-job-unique seeds.
BASE_SEED = 42
SEED_OFFSET = {"data": 0, "sig": 100, "mc1": 200, "mc2": 300}

# Shape-variation seeds (select.py's apply_shape draws a per-event random
# shift for shape_conv_up/dn; needs its own seed, kept well clear of the
# batch seeds above).
SHAPE_SEED_OFFSET = {"shape_conv_up": 1000, "shape_conv_dn": 2000}

IMG_MAIN  = "docker://docker.io/reanahub/reana-demo-bsm-search:1.0.0"
IMG_ROOT6 = "docker://docker.io/reanahub/reana-env-root6:6.18.04"

ROOTENV = "set +u && source /usr/local/bin/thisroot.sh && "


def shell_cmd(cmd, mkdir="$(dirname {output:q})"):
    """Give a rule its own dedicated log file and a guaranteed output dir.

    Two things go wrong under REANA that Snakemake's defaults assume won't:
    each rule runs in a fresh container, so nothing guarantees the output
    directory already exists; and REANA's own job-log viewer has, in
    practice, shown "running" for half an hour on a job that had already
    crashed. Both get handled once here rather than repeated per rule.
    Wrapping the ROOT environment sourcing *inside* the redirected block
    (rather than before it) means a failure in thisroot.sh itself lands in
    the log too, not just failures in the analysis command that follows it.
    `mkdir` defaults to the output's own directory; pass an explicit path for
    rules with more than one output or a scratch directory of their own.
    """
    return (
        "mkdir -p " + mkdir + " $(dirname {log:q}) && "
        "{{ " + ROOTENV + cmd.rstrip() + " ; }} > {log:q} 2>&1"
    )


wildcard_constraints:
    sample="data|sig|mc1|mc2",
    mc="mc1|mc2",
    region="signal|control",
    shapevar="shape_.+",
    b=r"\d+",


rule all:
    input:
        "plot/prefit.pdf",
        "plot/postfit.pdf",
        "hepdata/submission.zip",


# ---------------------------------------------------------------------------
# Generation (shared by all samples; Yadage stage "read" in each branch)
# ---------------------------------------------------------------------------
_GEN_CASE = "\n".join(
    f"          {s}) nevents={NEVENTS[s]}; offset={SEED_OFFSET[s]} ;;"
    for s in ["data", "sig", "mc1", "mc2"]
)


rule generate:
    input:
        "code/generantuple.py",
    output:
        temp("generated/{sample}/batch_{b}.root"),
    log:
        "logs/generate_{sample}_{b}.log",
    container:
        IMG_MAIN
    shell:
        shell_cmd("""
        case {wildcards.sample:q} in
""" + _GEN_CASE + """
        esac && \
        seed=$(( """ + str(BASE_SEED) + """ + offset + {wildcards.b} )) && \
        python code/generantuple.py {wildcards.sample:q} $nevents {output:q} $seed
        """)


rule merge_generated:
    input:
        lambda wc: expand(
            "generated/{s}/batch_{b}.root",
            s=wc.sample,
            b=range(BATCHES[wc.sample]),
        ),
    output:
        temp("merged/{sample}.root"),
    log:
        "logs/merge_generated_{sample}.log",
    container:
        IMG_ROOT6
    shell:
        shell_cmd("hadd {output:q} {input:q}")


# ---------------------------------------------------------------------------
# DATA branch (workflow_data.yml): signal region + data-driven multijet (qcd)
# ---------------------------------------------------------------------------
rule data_select:
    input:
        root="merged/data.root",
        script="code/select.py",
    output:
        temp("selected/data_{region}.root"),
    log:
        "logs/data_select_{region}.log",
    container:
        IMG_MAIN
    shell:
        shell_cmd("python code/select.py {input.root:q} {output:q} {wildcards.region:q} nominal")


rule data_hist_signal:
    input:
        root="selected/data_signal.root",
        script="code/histogram.py",
    output:
        temp("hists/data_signal.root"),
    log:
        "logs/data_hist_signal.log",
    container:
        IMG_MAIN
    shell:
        shell_cmd("python code/histogram.py {input.root:q} {output:q} data 1.0 nominal")


rule data_hist_control:
    input:
        root="selected/data_control.root",
        script="code/histogram.py",
    output:
        temp("hists/data_control.root"),
    log:
        "logs/data_hist_control.log",
    params:
        weight=QCD_WEIGHT,
    container:
        IMG_MAIN
    shell:
        shell_cmd("python code/histogram.py {input.root:q} {output:q} qcd {params.weight} nominal")


rule data_mergeall:
    input:
        "hists/data_signal.root",
        "hists/data_control.root",
    output:
        temp("branch/data.root"),
    log:
        "logs/data_mergeall.log",
    container:
        IMG_ROOT6
    shell:
        shell_cmd("hadd {output:q} {input:q}")


# ---------------------------------------------------------------------------
# SIGNAL branch (workflow_sig.yml)
# ---------------------------------------------------------------------------
rule sig_select:
    input:
        root="merged/sig.root",
        script="code/select.py",
    output:
        temp("selected/sig_signal.root"),
    log:
        "logs/sig_select.log",
    container:
        IMG_MAIN
    shell:
        shell_cmd("python code/select.py {input.root:q} {output:q} signal nominal")


rule sig_hist:
    input:
        root="selected/sig_signal.root",
        script="code/histogram.py",
    output:
        temp("branch/sig.root"),
    log:
        "logs/sig_hist.log",
    params:
        weight=SIG_WEIGHT,
    container:
        IMG_MAIN
    shell:
        shell_cmd("python code/histogram.py {input.root:q} {output:q} signal {params.weight} nominal")


# ---------------------------------------------------------------------------
# MC branch (wflow_all_mc.yml -> workflow_mc.yml + workflow_select_shape.yml)
# Weight variations: one select with all weight variations, one histogram job.
# Shape variations:  one select + one histogram_shape job per variation.
# ---------------------------------------------------------------------------
rule mc_select_weights:
    input:
        root="merged/{mc}.root",
        script="code/select.py",
    output:
        temp("selected/{mc}_signal_weights.root"),
    log:
        "logs/mc_select_weights_{mc}.log",
    container:
        IMG_MAIN
    shell:
        shell_cmd("python code/select.py {input.root:q} {output:q} signal " + WEIGHT_VARIATIONS)


rule mc_hist_weights:
    input:
        root="selected/{mc}_signal_weights.root",
        script="code/histogram.py",
    output:
        temp("hists/{mc}_weights.root"),
    log:
        "logs/mc_hist_weights_{mc}.log",
    container:
        IMG_MAIN
    shell:
        shell_cmd("""
        case {wildcards.mc:q} in
          mc1) weight=""" + str(MC_WEIGHTS['mc1']) + """ ;;
          mc2) weight=""" + str(MC_WEIGHTS['mc2']) + """ ;;
        esac && \
        python code/histogram.py {input.root:q} {output:q} {wildcards.mc:q} $weight """ + WEIGHT_VARIATIONS)


_SHAPE_SEED_CASE = "\n".join(
    f"          {mc}_{sv}) seed=$(( {BASE_SEED} + {SEED_OFFSET[mc]} + {SHAPE_SEED_OFFSET[sv]} )) ;;"
    for mc in MC_SAMPLES for sv in SHAPE_VARS
)


rule mc_select_shape:
    input:
        root="merged/{mc}.root",
        script="code/select.py",
    output:
        temp("selected/{mc}_signal_{shapevar}.root"),
    log:
        "logs/mc_select_shape_{mc}_{shapevar}.log",
    container:
        IMG_MAIN
    shell:
        shell_cmd("""
        case {wildcards.mc:q}_{wildcards.shapevar:q} in
""" + _SHAPE_SEED_CASE + """
        esac && \
        python code/select.py {input.root:q} {output:q} signal {wildcards.shapevar:q} $seed
        """)


rule mc_hist_shape:
    input:
        root="selected/{mc}_signal_{shapevar}.root",
        script="code/histogram.py",
    output:
        temp("hists/{mc}_{shapevar}.root"),
    log:
        "logs/mc_hist_shape_{mc}_{shapevar}.log",
    container:
        IMG_MAIN
    shell:
        shell_cmd("""
        case {wildcards.mc:q} in
          mc1) weight=""" + str(MC_WEIGHTS['mc1']) + """ ;;
          mc2) weight=""" + str(MC_WEIGHTS['mc2']) + """ ;;
        esac && \
        python code/histogram.py {input.root:q} {output:q} """ \
        "{wildcards.mc:q}_{wildcards.shapevar:q} $weight nominal '{{name}}'")


rule mc_mergeallvars:
    input:
        "hists/{mc}_weights.root",
        expand("hists/{{mc}}_{sv}.root", sv=SHAPE_VARS),
    output:
        temp("branch/{mc}.root"),
    log:
        "logs/mc_mergeallvars_{mc}.log",
    container:
        IMG_ROOT6
    shell:
        shell_cmd("hadd {output:q} {input:q}")


# ---------------------------------------------------------------------------
# Common tail: merge all branches -> workspace -> plots + HepData
# ---------------------------------------------------------------------------
rule merge_all:
    input:
        signal="branch/sig.root",
        data="branch/data.root",
        background=expand("branch/{mc}.root", mc=MC_SAMPLES),
    output:
        temp("merged_all/merged.root"),
    log:
        "logs/merge_all.log",
    container:
        IMG_ROOT6
    shell:
        shell_cmd("hadd {output:q} {input.signal:q} {input.data:q} {input.background:q}")


rule makews:
    input:
        root="merged_all/merged.root",
        script="code/makews.py",
    output:
        workspace=temp("ws/workspace_combined_meas_model.root"),
        xmldir=temp(directory("ws/xmldir")),
    log:
        "logs/makews.log",
    container:
        IMG_MAIN
    shell:
        shell_cmd(
            "python code/makews.py {input.root:q} ws/workspace {output.xmldir:q}",
            mkdir="{output.xmldir:q}",
        )


rule plot:
    input:
        "ws/workspace_combined_meas_model.root",
    output:
        prefit="plot/prefit.pdf",
        postfit="plot/postfit.pdf",
    log:
        "logs/plot.log",
    container:
        IMG_MAIN
    shell:
        shell_cmd(
            "hfquickplot write-vardef {input:q} combined plot/nominal_vals.yml && "
            "hfquickplot plot-channel {input:q} combined channel1 x plot/nominal_vals.yml "
            "-c qcd,mc2,mc1,signal -o {output.prefit:q} && "
            "hfquickplot fit {input:q} combined plot/fit_results.yml && "
            "hfquickplot plot-channel {input:q} combined channel1 x plot/fit_results.yml "
            "-c qcd,mc2,mc1,signal -o {output.postfit:q}",
            mkdir="plot",
        )


rule hepdata:
    input:
        root="ws/workspace_combined_meas_model.root",
        script="code/hepdata_export.py",
    output:
        "hepdata/submission.zip",
    log:
        "logs/hepdata.log",
    container:
        IMG_MAIN
    shell:
        shell_cmd(
            "python code/hepdata_export.py {input.root:q} "
            "hepdata/submission.yaml hepdata/data1.yaml && "
            "cd hepdata && zip submission.zip submission.yaml data1.yaml",
            mkdir="hepdata",
        )
