#!/bin/bash
# Snakemake --cluster-cancel hook: called with one or more HTCondor cluster
# IDs (the same ones condor/submit.sh printed) when Snakemake is interrupted.
#
# Without this, Ctrl+C only kills the local Snakemake process; the HTCondor
# jobs it already submitted keep sitting in the queue. Snakemake deletes its
# .snakemake/tmp.*/ jobscripts on exit, so if one of those orphaned jobs
# later gets matched to a slot, HTCondor can't find the file it's supposed
# to run and holds the job permanently ("No such file or directory"). This
# makes Ctrl+C actually remove the condor jobs too, so that can't happen.
condor_rm "$@"
