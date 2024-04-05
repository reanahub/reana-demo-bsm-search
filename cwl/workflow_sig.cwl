cwlVersion: v1.2
class: Workflow
requirements:
  ScatterFeatureRequirement: {}
inputs:
  mcweight: float
  nevents: int[]
outputs:
  mergedfile:
    outputSource: hist_merge/mergedfile
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
  select:
    run: clt/select_mc.cwl
    in:
      inputfile: merge/mergedfile
      outputfile:
        default: 'select_signal.root'
      region: 'signal'
      variations:
        default:
          - 'nominal'
    out: [outputfile]
  select_merge:
    run: clt/merge_root.cwl
    in:
      inputs: select/outputfile
      mergedfile:
        default: 'merged.root'
    out: [mergedfile]
  select_hist:
    run: clt/histogram.cwl
    in:
      inputfile: select_merge/mergedfile
      outputfile:
        default: 'hist.root'
      name:
        default: 'signal'
      variations:
        default:
          - 'nominal'
      weight: mcweight
    scatter: inputfile
    out: [outputfile]
  hist_merge:
    run: clt/merge_root.cwl
    in:
      inputs: select_hist/outputfile
      mergedfile:
        default: 'merged.root'
    out: [mergedfile]