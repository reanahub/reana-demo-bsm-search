cwlVersion: v1.2
class: CommandLineTool
requirements:
  DockerRequirement:
    dockerPull: docker.io/reanahub/reana-demo-bsm-search:1.0.0
inputs:
  data_bkg_hists: File
  workspace_prefix: string
  xml_dir: string
baseCommand: [bash, -c]
arguments:
  - valueFrom: |
      source /usr/local/bin/thisroot.sh
      python /code/makews.py $(inputs.data_bkg_hists) $(inputs.workspace_prefix) $(inputs.xml_dir)
outputs:
  workspace:
    outputBinding:
      glob: $(inputs.workspace_prefix)*combined*model.root
    type: File