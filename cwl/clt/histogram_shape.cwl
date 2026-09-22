cwlVersion: v1.2
class: CommandLineTool
requirements:
  DockerRequirement:
    dockerPull: docker.io/reanahub/reana-demo-bsm-search:1.0.0
inputs:
  inputfile: File
  outputfile: File
  name: string
  shapevar: string[]
  variations:
    inputBinding:
      itemSeparator: ','
    type: string[]
  weight: float
baseCommand: [bash, -c]
arguments:
  - valueFrom: |
      source /usr/local/bin/thisroot.sh
      python /code/histogram.py $(inputs.inputfile) $(inputs.outputfile) $(inputs.name)_$(inputs.shapevar) $(inputs.weight) $(inputs.variations) '{{name}}'
outputs:
  outputfile:
    outputBinding:
      glob: $(inputs.outputfile)
    type: File
