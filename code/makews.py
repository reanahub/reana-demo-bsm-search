import json
import sys

import ROOT
import yaml


DEFAULT_MODEL_CONFIG = {
    "backgrounds": {"mc1": {}, "mc2": {}},
    "systematics": {
        "weight": {
            "weight_var1": {
                "up": {"name": "weight_var1_up", "factor": 1.05},
                "down": {"name": "weight_var1_dn", "factor": 0.95},
            }
        },
        "shape": {
            "shape_conv": {
                "up": {"name": "shape_conv_up", "shift": [0, 1]},
                "down": {"name": "shape_conv_dn", "shift": [-1, 0]},
            }
        },
    },
}


def load_model_config(source):
    if source is None:
        return DEFAULT_MODEL_CONFIG
    if source.lstrip().startswith("{"):
        return json.loads(source)
    with open(source) as config_file:
        return yaml.safe_load(config_file)


def add_systematics(sample, sample_name, input_file, systematics):
    for systematic_group in systematics.values():
        for systematic_name, variations in systematic_group.items():
            sample.AddHistoSys(
                f"{sample_name}_{systematic_name}",
                f"{sample_name}_{variations['down']['name']}",
                input_file,
                "",
                f"{sample_name}_{variations['up']['name']}",
                input_file,
                "",
            )


def main():
    data_bkg_signal_file = sys.argv[1]
    output_prefix = sys.argv[2]
    xml_dir = sys.argv[3]
    model_config = load_model_config(sys.argv[4] if len(sys.argv) > 4 else None)

    # Create the measurement
    meas = ROOT.RooStats.HistFactory.Measurement("meas", "meas")

    meas.SetOutputFilePrefix(output_prefix)
    meas.SetPOI("SigXsecOverSM")

    meas.SetLumi(1.0)
    meas.SetLumiRelErr(0.10)
    # meas.SetExportOnly(True)

    # Create a channel

    chan = ROOT.RooStats.HistFactory.Channel("channel1")
    chan.SetData("data_nominal", data_bkg_signal_file)

    # Now, create some samples

    signal = ROOT.RooStats.HistFactory.Sample(
        "signal", "signal_nominal", data_bkg_signal_file
    )
    signal.AddNormFactor("SigXsecOverSM", 1, 0, 3)
    chan.AddSample(signal)

    qcd = ROOT.RooStats.HistFactory.Sample(
        "qcd", "qcd_nominal", data_bkg_signal_file
    )
    chan.AddSample(qcd)

    for background_name in model_config["backgrounds"]:
        background = ROOT.RooStats.HistFactory.Sample(
            background_name,
            f"{background_name}_nominal",
            data_bkg_signal_file,
        )
        add_systematics(
            background,
            background_name,
            data_bkg_signal_file,
            model_config["systematics"],
        )
        chan.AddSample(background)

    # Done with this channel
    # Add it to the measurement:

    meas.AddChannel(chan)

    # Collect the histograms from their files and print some output.
    meas.CollectHistograms()
    meas.PrintTree()

    # One can print XML code to an
    # output directory:
    # meas.PrintXML("xmlFromCCode", meas.GetOutputFilePrefix())

    meas.PrintXML(xml_dir, meas.GetOutputFilePrefix())

    # Now, do the measurement
    ROOT.RooStats.HistFactory.MakeModelAndMeasurementFast(meas)


if __name__ == "__main__":
    main()
