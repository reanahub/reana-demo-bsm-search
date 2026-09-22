cwlVersion: v1.2
class: Workflow
requirements:
  SubworkflowFeatureRequirement: {}
inputs: {}
outputs:
  postfit:
    outputSource: plot/postfit
    type: File
  prefit:
    outputSource: plot/prefit
    type: File
steps:
  all_bkg_mc:
    run: wflow_all_mc.cwl
    in:
      mcname:
        default: ['mc1', 'mc2']
      mcweight:
        default: [0.01875, 0.0125]
      nevents: 
        default: [40000,40000,40000,4000]
    out: [mergedfile]
  data:
    run: workflow_data.cwl
    in:
      nevents:
        default: [20000,20000,20000,20000,20000]
    out: [mergedfile]
  signal:
    run: workflow_sig.cwl
    in:
      nevents:
        default: [40000,40000]
      mcweight:
        default: 0.0025
    out: [mergedfile]
  merge:
    run: clt/merge_root_allpars.cwl
    in:
      backgorund: all_bkg_mc/mergedfile
      data: data/mergedfile
      mergedfile:
        valueFrom: 'merged.root'
      signal: signal/mergedfile
    out: [mergedfile]
  makews:
    run: clt/makews.cwl
    in:
      data_bkg_hists: merge/mergedfile
      workspace_prefix:
        default: 'results/workspace'
      xml_dir:
        default: 'xmldir'
    out: [workspace]
  plot:
    run: clt/plot.cwl
    in:
      combined_model: makews/workspace
      nominal_vals:
        default: 'nominal_vals.yml'
      fit_results:
        default: 'fit_results.yml'
      prefit_plot:
        default: 'prefit.pdf'
      postfit_plot:
        default: 'postfit.pdf'
    out: [postfit, prefit]
  hepdata:
    run: clt/hepdata.cwl
    in:
      combined_model: makews/workspace
      hepdata_submission_zip:
        default: 'submission.zip'
      hepdata_submission_yaml:
        default: 'submission.yaml'
      hepdata_data1_yaml:
        default: 'data1.yaml'
    out: [hepdata_submission_zip]
