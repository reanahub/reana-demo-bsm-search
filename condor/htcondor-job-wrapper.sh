#!/bin/bash
# Used via the "job_wrapper" resource in profiles/lxbatch/profile.v9+.yaml.
#
# HTCondor launching sys.executable (our AFS venv's python, a symlink into
# the CVMFS LCG view) directly as the job's own "executable" attribute
# crashes on the worker with "Failed to import encodings module", even
# though the same interpreter runs fine when invoked from inside a shell
# script. This wrapper exists to be that shell.
#
# The plugin hands it the complete, already-assembled command (python path,
# -m snakemake, and the real job args) as arguments, so just re-exec it
# verbatim rather than building a new command ourselves.
#
# The plugin also never sets HTCondor's initialdir, so without the cd below
# the job runs in HTCondor's own scratch directory on the worker: the rule's
# shell command still succeeds, but Snakemake can't find the relative-path
# outputs afterwards. $HOME is already the AFS side of the checkout on
# lxplus; override REPO_DIR before submitting if you cloned it elsewhere.
cd "${REPO_DIR:-$HOME/reana-demo-bsm-search}" || exit 1
exec "$@"
