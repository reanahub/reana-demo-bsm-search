cwlVersion: v1.2
class: Workflow
requirements:
  ScatterFeatureRequirement: {}
inputs:
  inputfile: File
  mcname: string
  mcweight: float
  shapevar: string[]
outputs:
  outputfile:
    outputSource: hist/outputfile
    type: File
steps:
  select:
    run: clt/select_mc.cwl
    in:
      inputfile: inputfile
      outputfile:
        default: 'select_signal.root'
      region:
        default: 'signal'
      variations: shapevar
    scatter: inputfile
    out: [outputfile]
  merge:
    run: clt/merge_root.cwl
    in:
      inputs: select/outputfile
      mergedfile:
        default: 'merged.root'
    out: [mergedfile]
  hist:
    run: clt/histogram_shape.cwl
    in:
      inputfile: merge/mergedfile
      outputfile:
        default: 'hist.root'
      name: mcname
      shapevar: shapevar
      variations:
        default:
          - 'nominal'
      weight: mcweight
    out: [outputfile]