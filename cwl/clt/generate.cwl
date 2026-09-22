cwlVersion: v1.2
class: CommandLineTool
requirements:
  DockerRequirement:
    dockerPull: docker.io/reanahub/reana-demo-bsm-search:1.0.0
inputs:
  nevents: int
  outputfile: File
  type: string
baseCommand: [bash, -c]
arguments:
  - valueFrom: |
      source /usr/local/bin/thisroot.sh
      python /code/generantuple.py $(inputs.type) $(inputs.nevents) $(inputs.outputfile)
outputs:
  outputfile:
    outputBinding:
      glob: $(inputs.outputfile)
    type: File
