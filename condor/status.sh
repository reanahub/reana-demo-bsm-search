#!/bin/bash
# Snakemake --cluster-status hook: given the cluster ID that condor/submit.sh
# printed, report exactly one of "running", "success", or "failed" so
# Snakemake knows whether to keep waiting, mark the job done, or retry/abort.
#
# A completed job can stay visible in condor_q for a while after it's
# actually finished (grace period before condor sweeps it into history), so
# this reads the JobStatus code itself rather than treating "condor_q printed
# any digit" as "still running" -- that included status 4 (Completed) and
# made every job look permanently running until it aged out of the queue.
# No set -e here on purpose: this script must always print exactly one of
# the three words below, even when a sub-command comes back empty.
set -uo pipefail

jobid="$1"

status=$(condor_q "$jobid" -af JobStatus 2>/dev/null)

if [ -z "$status" ]; then
    # Already gone from the live queue: the only record left is history.
    exit_code=$(condor_history "$jobid" -af ExitCode 2>/dev/null | head -n1)
    if [ "$exit_code" == "0" ]; then
        echo success
    else
        echo failed
    fi
    exit 0
fi

case "$status" in
1 | 2 | 6)
    # Idle, running, or transferring output: still going.
    echo running
    ;;
4)
    # Completed, but condor_q hasn't aged it out yet; check how it exited.
    exit_code=$(condor_q "$jobid" -af ExitCode 2>/dev/null)
    if [ "$exit_code" == "0" ]; then
        echo success
    else
        echo failed
    fi
    ;;
*)
    # 3 = removed, 5 = held, anything else unexpected: treat as failed.
    echo failed
    ;;
esac
