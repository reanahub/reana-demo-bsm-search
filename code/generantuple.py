import array
import json
import math
import random
import sys


DEFAULT_GENERATOR_CONFIG = {
    "samples": {
        "qcd": {"loc": 5, "scale": 4},
        "mc1": {"loc": -3, "scale": 1.5},
        "mc2": {"loc": -1, "scale": 0.9},
        "sig": {"loc": 1, "scale": 0.5},
    },
    "data": {
        "control_region_fraction": 0.8,
        "signal_region_composition": {"mc1": 0.15, "mc2": 0.1, "qcd": 0.75},
    },
}


def normalise_workflow_config(config):
    return {
        "samples": {
            **{
                name: sample_config["generator"]
                for name, sample_config in config["backgrounds"].items()
            },
            "qcd": config["data"]["qcd_generator"],
            "sig": config["signal"]["generator"],
        },
        "data": {
            "control_region_fraction": config["data"]["control_region_fraction"],
            "signal_region_composition": {
                **{
                    name: sample_config["data_fraction"]
                    for name, sample_config in config["backgrounds"].items()
                },
                "qcd": config["data"]["qcd_fraction"],
            },
        },
    }


def load_generator_config(source):
    if source is None:
        return DEFAULT_GENERATOR_CONFIG
    if source.lstrip().startswith("{"):
        return json.loads(source)

    import yaml

    with open(source) as config_file:
        return normalise_workflow_config(yaml.safe_load(config_file))


def validate_data_composition(config):
    total_fraction = sum(config["data"]["signal_region_composition"].values())
    if not math.isclose(total_fraction, 1.0, rel_tol=0.0, abs_tol=1e-9):
        raise ValueError(
            "Signal-region data fractions must sum to 1, "
            f"but sum to {total_fraction}"
        )


def sample(name, config):
    settings = config["samples"][name]
    return random.normalvariate(settings["loc"], settings["scale"])


def sample_component(composition):
    value = random.random()
    cumulative_fraction = 0.0
    for name, fraction in composition.items():
        cumulative_fraction += fraction
        if value < cumulative_fraction:
            return name
    raise RuntimeError("Could not sample from the configured data composition")


def sample_data(config):
    event_data = {}
    if random.random() < config["data"]["control_region_fraction"]:
        event_data["region"] = 0
        event_data["var"] = sample("qcd", config)
    else:
        event_data["region"] = 1
        component = sample_component(config["data"]["signal_region_composition"])
        event_data["var"] = sample(component, config)
    return event_data


def sample_mc(name, config):
    event_data = {}
    event_data["region"] = 1
    event_data["var"] = sample(name, config)
    return event_data


def main():
    gentype = sys.argv[1]
    nevents = int(sys.argv[2])
    outputfile = sys.argv[3]
    seed = int(sys.argv[4]) if len(sys.argv) > 4 else -1
    generator_config = load_generator_config(sys.argv[5] if len(sys.argv) > 5 else None)

    if seed >= 0:
        random.seed(seed)
    validate_data_composition(generator_config)

    import ROOT

    fout = ROOT.TFile.Open(outputfile, "RECREATE")
    ntout = ROOT.TNtuple("ntuple", "ntuple", "region:var:weight")

    for _ in range(nevents):
        if gentype == "data":
            e = sample_data(generator_config)
            a = array.array("f")
            a.fromlist([e["region"], e["var"], 1.0])
            ntout.Fill(a)
        else:
            e = sample_mc(gentype, generator_config)
            a = array.array("f")
            a.fromlist([e["region"], e["var"], 1.0])
            ntout.Fill(a)

    ntout.Write()
    fout.Close()


if __name__ == "__main__":
    main()
