cwlVersion: v1.2
class: Workflow
requirements:
  ScatterFeatureRequirement: {}
  SubworkflowFeatureRequirement: {}
inputs:
  nevents: int[]
  mcname: string[]
  mcweight: float[]
outputs:
  mergedfile:
    outputSource: merge/mergedfile
    type: File[]
steps:
  run_mc:
    run: workflow_mc.cwl
    in:
      nevents: nevents
      mcname: mcname
      mcweight: mcweight
      shapevars:
        default:
          - - shape_conv_up
          - - shape_conv_dn
      weightvariations:
        default:
          - 'nominal'
          - 'weight_var1_up'
          - 'weight_var1_dn'
    scatter:
      - mcname
      - mcweight
    out: [mergeallvars]
  merge:
    run: clt/merge_root.cwl
    in:
      inputs: run_mc/mergeallvars
      mergedfile:
        default: 'merged.root'
    out: [mergedfile]