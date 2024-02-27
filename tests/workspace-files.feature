# Tests for the presence of files in the workspace

Feature: Workspace files

    As a researcher,
    I want to make sure that my workflow produces the expected files,
    and that the relevant input files are present in the workspace,
    so that I can be sure that the workflow outputs are correct.

    Scenario: The workspace downloads the relevant input files
        When the workflow execution completes
        Then the workspace should contain "data/read_0/output_one.root"
        And the workspace should contain "signal/read_0/output_one.root"
        And the workspace should contain "all_bkg_mc/run_mc_1/read_0/output_one.root"

    Scenario: The files used to build the outputs contain the expected values
        When the workflow is finished
        Then the file "plot/nominal_vals.yml" should include
            """
            Lumi:
              err: 0.0
              max: 10.0
              min: 0.0
              val: 1.0
            """

    Scenario: The expected plots are present in the workspace
        When the workflow is finished
        Then the workspace should include "plot/prefit.pdf"
        And the workspace should include "plot/postfit.pdf"
        And all the outputs should be included in the workspace

