cwlVersion: v1.2
class: CommandLineTool
requirements:
  DockerRequirement:
    dockerPull: docker.io/reanahub/reana-demo-bsm-search:1.0.0
inputs:
  combined_model: File
  hepdata_data1_yaml: string
  hepdata_submission_yaml: string
  hepdata_submission_zip: string
baseCommand: [bash, -c]
arguments:
  - valueFrom: |
      source /usr/local/bin/thisroot.sh
      python /code/hepdata_export.py $(inputs.combined_model) $(inputs.hepdata_submission_yaml) $(inputs.hepdata_data1_yaml)
      zip $(inputs.hepdata_submission_zip) $(inputs.hepdata_submission_yaml) $(inputs.hepdata_data1_yaml)
outputs:
  hepdata_submission_zip:
    outputBinding:
      glob: $(inputs.hepdata_submission_zip)
    type: File
