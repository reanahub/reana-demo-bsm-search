cwlVersion: v1.2
class: CommandLineTool
requirements:
  DockerRequirement:
    dockerPull: docker.io/reanahub/reana-demo-bsm-search:1.0.0
inputs:
  combined_model: File
  fit_results: string
  nominal_vals: string
  postfit_plot: string
  prefit_plot: string
baseCommand: [bash, select.sh]
arguments:
  - valueFrom: |
      source /usr/local/bin/thisroot.sh
      hfquickplot write-vardef $(inputs.combined_model) combined $(inputs.nominal_vals)
      hfquickplot plot-channel 4(inputs.combined_model) combined channel1 x $(inputs.nominal_vals) -c qcd,mc2,mc1,signal -o $(inputs.prefit_plot)
      hfquickplot fit $(inputs.combined_model) combined $(inputs.fit_results)
      hfquickplot plot-channel $(inputs.combined_model) combined channel1 x $(inputs.fit_results) -c qcd,mc2,mc1,signal -o $(inputs.postfit_plot)
outputs:
  postfit:
    outputBinding:
      glob: $(inputs.postfit_plot)
    type: File
  prefit:
    outputBinding:
      glob: $(inputs.prefit_plot)
    type: File
