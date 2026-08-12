#!/bin/bash
# Snakemake --cluster hook: submits one Snakemake-generated jobscript to
# HTCondor and prints the numeric cluster ID on stdout (Snakemake reads that
# ID back via condor/status.sh to know when the job is done).
#
# condor_submit takes a submit-description file, not a bare command, so this
# writes a minimal one per job rather than trying to pass everything on the
# command line.
set -euo pipefail

jobscript="$1"
mkdir -p logs/condor
chmod +x "$jobscript"

submitfile=$(mktemp --suffix=.sub)
trap 'rm -f "$submitfile"' EXIT

cat >"$submitfile" <<EOF
universe    = vanilla
executable  = ${jobscript}
output      = logs/condor/\$(Cluster).\$(Process).out
error       = logs/condor/\$(Cluster).\$(Process).err
log         = logs/condor/\$(Cluster).\$(Process).log
getenv      = True
+JobFlavour = "espresso"
should_transfer_files = IF_NEEDED
queue
EOF

# condor_submit prints "... submitted to cluster N." on success; pull out N.
condor_submit "$submitfile" | grep -oP '(?<=submitted to cluster )\d+'
