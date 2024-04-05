cwlVersion: v1.2
class: Workflow
requirements:
  ScatterFeatureRequirement: {}
inputs:
  nevents: int[]
outputs:
  mergedfile:
    outputSource: mergeall/mergedfile
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
  select_signal:
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
  select_signal_merge:
    run: clt/merge_root.cwl
    in:
      inputs: select_signal/outputfile
      mergedfile:
        default: 'merged.root'
    out: [mergedfile]
  select_control:
    run: clt/select_mc.cwl
    in:
      inputfile: merge/mergedfile
      outputfile:
        default: 'select_control.root'
      region: 'control'
      variations:
        default:
          - 'nominal'
    scatter: inputfile
    out: [outputfile]
  select_control_merge:
    run: clt/merge_root.cwl
    in:
      inputs: select_control/outputfile
      mergedfile:
        default: 'merged.root'
    out: [mergedfile]
  select_signal_hist:
    run: clt/histogram.cwl
    in:
      inputfile: select_signal_merge/mergedfile
      outputfile:
        default: 'hist.root'
      name:
        default: 'data'
      variations:
        default:
          - 'nominal'
      weight:
        default: 1.0
    out: [outputfile]
  select_control_hist:
    run: clt/histogram.cwl
    in:
      inputfile: select_control_merge/mergedfile
      outputfile:
        default: 'hist.root'
      name:
        default: 'qcd'
      variations:
        default:
          - 'nominal'
      weight:
        default: 0.1875
    out: [outputfile]
  mergeall:
    run: clt/merge_root.cwl
    in:
      inputs:
        source:
          - select_signal_hist/outputfile
          - select_control_hist/outputfile
      mergedfile:
        default: 'merged.root'
    out: [mergedfile]