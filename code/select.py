import array
import json
import random
import sys

import ROOT


DEFAULT_VARIATION_CONFIG = {
    "weight_var1_up": {"type": "weight", "factor": 1.05},
    "weight_var1_dn": {"type": "weight", "factor": 0.95},
    "shape_conv_up": {"type": "shape", "shift": [0, 1]},
    "shape_conv_dn": {"type": "shape", "shift": [-1, 0]},
}


def normalise_workflow_config(config):
    definitions = {}
    for variation_type, systematics in config["systematics"].items():
        for systematic in systematics.values():
            for variation in (systematic["up"], systematic["down"]):
                definitions[variation["name"]] = {
                    "type": variation_type,
                    **{
                        key: value
                        for key, value in variation.items()
                        if key != "name"
                    },
                }
    return definitions


def load_variation_config(source):
    if source is None:
        return DEFAULT_VARIATION_CONFIG
    if source.lstrip().startswith("{"):
        return json.loads(source)

    import yaml

    with open(source) as config_file:
        return normalise_workflow_config(yaml.safe_load(config_file))


def apply_shape(value, variation_name, variation_config):
    shift_range = variation_config[variation_name]["shift"]
    if shift_range[0] > shift_range[1]:
        raise ValueError(f"Invalid shift range for {variation_name}: {shift_range}")
    return value + random.uniform(*shift_range)


def calc_weight(variation_name, variation_config):
    return variation_config[variation_name]["factor"]


def main():
    inputfile = sys.argv[1]
    outputfile = sys.argv[2]
    selection = sys.argv[3]
    variations = sys.argv[4].split(",")
    seed = int(sys.argv[5]) if len(sys.argv) > 5 else -1
    variation_config = load_variation_config(
        sys.argv[6] if len(sys.argv) > 6 else None
    )

    if seed >= 0:
        random.seed(seed)

    unknown_variations = set(variations) - {"nominal", *variation_config}
    if unknown_variations:
        raise ValueError(f"Unknown variations: {sorted(unknown_variations)}")

    shape_vars = [
        name
        for name in variations
        if name != "nominal" and variation_config[name]["type"] == "shape"
    ]
    weight_vars = [
        name
        for name in variations
        if name != "nominal" and variation_config[name]["type"] == "weight"
    ]

    nominal = "nominal" in variations
    if (nominal or weight_vars) and shape_vars:
        raise ValueError(
            "Shape variations cannot run together with nominal or weight variations"
        )
    if weight_vars and not nominal:
        raise ValueError("Nominal must run together with weight variations")
    if len(shape_vars) > 1:
        raise ValueError("Shape variations must run one at a time")

    fin = ROOT.TFile.Open(inputfile)
    ntin = fin.Get("ntuple;1")

    fout = ROOT.TFile.Open(outputfile, "RECREATE")
    varlist = "region:var:weight_nominal"
    if weight_vars:
        varlist = varlist + ":" + ":".join(weight_vars)
    print(varlist)
    ntout = ROOT.TNtuple("ntuple", "ntuple", varlist)
    ROOT.SetOwnership(ntout, False)

    for event in ntin:
        region, value = event.region, event.var

        if shape_vars:
            value = apply_shape(value, shape_vars[0], variation_config)

        weights = [1.0] + [
            calc_weight(weight_name, variation_config) for weight_name in weight_vars
        ]
        if selection == "signal" and not (region == 1.0 and -5 < value < 5):
            continue
        if selection == "control" and not (region == 0.0 and -5 < value < 5):
            continue

        values = array.array("f", [region, value, *weights])
        ntout.Fill(values)

    ntout.Write()
    fout.Close()


if __name__ == "__main__":
    main()
