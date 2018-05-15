import ROOT
import sys

def main():
    DataBkgSigFile  = sys.argv[1]
    OutputPrefix = sys.argv[2]
    xml_dir = sys.argv[3]

    # Create the measurement
    meas = ROOT.RooStats.HistFactory.Measurement("meas", "meas")

    meas.SetOutputFilePrefix(OutputPrefix)
    meas.SetPOI("SigXsecOverSM")

    meas.SetLumi(1.0)
    meas.SetLumiRelErr(0.10)
    # meas.SetExportOnly(True)

    # Create a channel

    chan = ROOT.RooStats.HistFactory. Channel("channel1")
    chan.SetData("data_nominal", DataBkgSigFile)

    # Now, create some samples

    signal = ROOT.RooStats.HistFactory.Sample("signal", "signal_nominal", DataBkgSigFile)
    signal.AddNormFactor("SigXsecOverSM", 1, 0, 3)
    chan.AddSample(signal)


    qcd = ROOT.RooStats.HistFactory.Sample("qcd", "qcd_nominal", DataBkgSigFile)
    chan.AddSample(qcd)


    mc1 = ROOT.RooStats.HistFactory.Sample("mc1", "mc1_nominal", DataBkgSigFile)
    mc1.AddHistoSys('mc1_weight_var1', 'mc1_weight_var1_dn', DataBkgSigFile, '', 'mc1_weight_var1_up', DataBkgSigFile, '')
    mc1.AddHistoSys('mc1_shape_conv', 'mc1_shape_conv_dn', DataBkgSigFile, '', 'mc1_shape_conv_up', DataBkgSigFile, '')
    chan.AddSample(mc1)

    mc2 = ROOT.RooStats.HistFactory.Sample("mc2", "mc2_nominal", DataBkgSigFile)
    mc2.AddHistoSys('mc2_weight_var1', 'mc2_weight_var1_dn', DataBkgSigFile, '', 'mc2_weight_var1_up', DataBkgSigFile, '')
    mc2.AddHistoSys('mc2_shape_conv', 'mc2_shape_conv_dn', DataBkgSigFile, '', 'mc2_shape_conv_up', DataBkgSigFile, '')
    chan.AddSample(mc2)

    # Done with this channel
    # Add it to the measurement:

    meas.AddChannel(chan)

    # Collect the histograms from their files,
    # print some output, 
    meas.CollectHistograms()
    meas.PrintTree();

    # One can print XML code to an
    # output directory:
    # meas.PrintXML("xmlFromCCode", meas.GetOutputFilePrefix());

    meas.PrintXML(xml_dir, meas.GetOutputFilePrefix());

    # Now, do the measurement
    ROOT.RooStats.HistFactory.MakeModelAndMeasurementFast(meas);


if __name__ == '__main__':
    main()