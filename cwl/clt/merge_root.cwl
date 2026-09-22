cwlVersion: v1.2
class: CommandLineTool
requirements:
  DockerRequirement:
    dockerPull: docker.io/reanahub/reana-env-root6:6.18.04
inputs:
  mergedfile: string
  inputs: File[]
baseCommand: [bash, -c]
arguments:
  - valueFrom: |
      source /usr/local/bin/thisroot.sh
      hadd $(inputs.mergedfile) $(inputs.inputs)
outputs:
  mergedfile:
    outputBinding:
      glob: $(inputs.mergedfile)
    type: File
