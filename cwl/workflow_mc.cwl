cwlVersion: v1.2
class: Workflow
requirements:
  ScatterFeatureRequirement: {}
  SubworkflowFeatureRequirement: {}
inputs:
  mcname: string
  mcweight: float
  nevents: int[]
  shapevar:
    type:
      type: array
      items:
       type: array
       items: string
  weightvariations: string[]
outputs:
  mergedfile:
    outputSource: mergeallvars/mergedfile
    type: File[]
steps:
  read:
    run: clt/generate.cwl
    in:
      nevents: nevents
      outputfile:
        default: 'output_one.root'
      type:
        default: 'sig'
    scatter: nevents
    out: [outputfile]
  merge:
    run: clt/merge_root.cwl
    in:
      inputs: read/outputfile
      mergedfile:
        default: 'merged.root'
    out: [mergedfile]
  select_signal_shapevars:
    run: workflow_select_shape.cwl
    in:
      inputfile: merge/mergedfile
      mcname: mcname
      mcweight: mcweight
      shapevar: shapevar
    scatter: shapevar
    out: [outputfile]
  select_signal:
    run: clt/select_mc.cwl
    in:
      inputfile: merge/mergedfile
      outputfile:
        default: 'select_signal.root'
      region:
        default: 'signal'
      variations:
        default:
          - 'nominal'
    out: [outputfile]
  select_signal_merge:
    run: clt/merge_root.cwl
    in:
      inputs: select_signal/outputfile
      mergedfile:
        default: 'merged.root'
    out: [mergedfile]
  select_signal_hist:
    run: clt/histogram.cwl
    in:
      inputfile: select_signal_merge/mergedfile
      outputfile:
        default: 'hist.root'
      name: mcname
      variations: weightvariations
      weight: mcweight
    out: [outputfile]
  mergeweights:
    run: clt/merge_root.cwl
    in:
      inputs: select_signal_hist/outputfile
      mergedfile:
        default: 'merged.root'
    out: [mergedfile]
  mergeshapes:
    run: clt/merge_root.cwl
    in:
      inputs: select_signal_shapevars/outputfile
      mergedfile:
        default: 'merged.root'
    out: [mergedfile]
  mergeallvars:
    run: clt/merge_root.cwl
    in:
      inputs:
        source:
          - mergeweights/mergedfile
          - mergeshapes/mergedfile
      mergedfile:
        default: 'merged.root'
    out: [mergedfile]