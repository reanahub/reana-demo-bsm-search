cwlVersion: v1.2
class: CommandLineTool
requirements:
  DockerRequirement:
    dockerPull: docker.io/reanahub/reana-demo-bsm-search:1.0.0
inputs:
  inputfile: File
  outputfile: File
  region: string
  variations:
    inputBinding:
      itemSeparator: ","
    type: string[]
baseCommand: [bash, -c]
arguments:
  - valueFrom: |
      source /usr/local/bin/thisroot.sh
      python /code/select.py $(inputs.inputfile) $(inputs.outputfile) $(inputs.region) $(inputs.variations)
outputs:
  outputfile:
    outputBinding:
      glob: $(inputs.outputfile)
    type: File
