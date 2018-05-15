# import ROOT
# outputfile = 'out.root'
# f = ROOT.TFile(outputfile)

import json
import random
import sys

mc_settings = {
    'qcd': {'loc': 5, 'scale': 4},
    'mc1': {'loc': -3, 'scale': 1.5},
    'mc2': {'loc': -1, 'scale': 0.9},
    'sig': {'loc':  1, 'scale': 0.5},
}
cats = ['mc1','mc2','qcd','sig']

def sample(name):
    return random.normalvariate(mc_settings[name]['loc'],mc_settings[name]['scale'])



BRs = [0.15,0.1,0.75,0.0] #mc1, mc2, qcd, mc_sig
cuts = [0]
for x in BRs:
    cuts.append(cuts[-1]+x)

hidden_split = 0.8 #much more data in qcd-pure region

def sample_data():
    event_data = {}
    if random.random() < hidden_split:
        event_data['region'] = 0
        event_data['var'] = sample('qcd')
    else:
        event_data['region'] = 1

        rand = random.random()
        cat = sum([1 if rand > x else 0 for x in cuts])
        event_data['var'] = sample(cats[cat-1])
    return event_data

def sample_mc(name):
    event_data = {}
    event_data['region'] = 1
    event_data['var'] = sample(name)
    return event_data

def main():
    gentype = sys.argv[1]
    nevents = int(sys.argv[2])
    outputfile = sys.argv[3]

    import ROOT
    import array
    fout = ROOT.TFile.Open(outputfile,'RECREATE')
    ntout= ROOT.TNtuple('ntuple','ntuple','region:var:weight')

    for i in range(nevents):
        if gentype == 'data':
            e = sample_data()
            a = array.array('f')
            a.fromlist([e['region'],e['var'],1.0])
            ntout.Fill(a)
        else:
            e = sample_mc(gentype)
            a = array.array('f')
            a.fromlist([e['region'],e['var'],1.0])
            ntout.Fill(a)

    ntout.Write()
    fout.Close()
    # json.dump(events, open(outputfile,'w'))


if __name__ == '__main__':
    main()