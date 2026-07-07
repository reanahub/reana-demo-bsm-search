
# Tests for the expected workflow log messages

Feature: Log messages

    As a researcher,
    I want to be able to see the log messages of my workflow execution,
    So that I can verify that the workflow ran correctly.

    Scenario: The Snakemake workflow start has produced the expected messages
        When the workflow is finished
        Then the engine logs should contain "Building DAG of jobs"
        And the engine logs should contain "Job stats"

    Scenario: The plotting step has produced the expected messages
        When the workflow is finished
        Then the engine logs should contain "rule plot"
        And the job logs for the "plot" step should contain
            """
             PARAMETER DEFINITIONS:
                NO.   NAME         VALUE      STEP SIZE      LIMITS
                 1 Lumi         1.00000e+00  5.00000e-01    0.00000e+00  1.00000e+01
                 2 SigXsecOverSM   1.00000e+00  3.00000e-01    0.00000e+00  3.00000e+00
                 3 alpha_mc1_shape_conv   0.00000e+00  1.00000e+00   -5.00000e+00  5.00000e+00
                 4 alpha_mc1_weight_var1   0.00000e+00  1.00000e+00   -5.00000e+00  5.00000e+00
                 5 alpha_mc2_shape_conv   0.00000e+00  1.00000e+00   -5.00000e+00  5.00000e+00
                 6 alpha_mc2_weight_var1   0.00000e+00  1.00000e+00   -5.00000e+00  5.00000e+00
            """
        And the engine logs should contain "plot/prefit.pdf"

    Scenario: The hepdata step has produced the expected messages
        When the workflow is finished
        Then the job logs for the "hepdata" step should contain
            """
            INFO:InputArguments -- RooAbsReal::createHistogram(L_x_signal_channel1_overallSyst_x_Exp) INFO: Model has intrinsic binning definition, selecting that binning for the histogram
            """
        And the engine logs should contain "hepdata/submission.zip"
