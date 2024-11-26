cwlVersion: v1.2
class: CommandLineTool
requirements:
  DockerRequirement:
    dockerPull: docker.io/reanahub/reana-env-root6:6.18.04
inputs:
  background: string
  data: string
  mergedfile: string
  signal: File[]
baseCommand: [bash, -c]
arguments:
  - valueFrom: |
      source /usr/local/bin/thisroot.sh
      hadd $(inputs.mergedfile) $(inputs.signal) $(inputs.data) $(inputs.background)
outputs:
  mergedfile:
    outputBinding:
      glob: $(inputs.mergedfile)
    type: File
