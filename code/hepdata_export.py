import os
import sys

import ROOT
import yaml

import hftools.hepdata as hft_hepdata

main_submission = '''\
---
comment: | # preserve newlines
  Hello World.

---
# Start a new YAML document to indicate a new data table.
# This is Table 1.
name: "Table 1"
location: "Not in Manuscript"
description: The measured fiducial cross sections.  The first systematic uncertainty is the combined systematic uncertainty excluding luminosity, the second is the luminosity
keywords: # used for searching, possibly multiple values for each keyword
  - {name: reactions, values: [P P --> Z0 Z0 X]}
data_file: data1.yaml
data_license: # (optional) you can specify a license for the data
  name: "GPL 2"
  url: "url for license"
  description: "Tell me about it. This can appear in the main record display" # (optional)
'''

def main():
    sampledef = [
        ('signal', {'systs': {}, 'HFname': 'signal'}),
        ('mc1', {'systs': {}, 'HFname': 'mc1'}),
        ('mc2', {'systs': {}, 'HFname': 'mc2'}),
        ('qcd', {'systs': {}, 'HFname': 'qcd'}),
    ]

    rootfile = sys.argv[1]
    try:
        submission_yaml = sys.argv[2]
    except:
        submission_yaml = 'submission.yaml'
    try:
        data1_yaml = sys.argv[3]
    except:
        data1_yaml = 'data1.yaml'
    observable = 'x'
    channel = 'channel1'
    workspace = 'combined'

    f  = ROOT.TFile.Open(str(rootfile))
    ws = f.Get(str(workspace))

    hepdata_table = hft_hepdata.hepdata_table(ws,channel,observable,sampledef)

    with open(submission_yaml,'w') as f:
        f.write(main_submission)

    with open(data1_yaml,'w') as f:
        f.write(yaml.safe_dump(hepdata_table,default_flow_style = False))


if __name__ == '__main__':
    main()
