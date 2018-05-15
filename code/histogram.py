import sys
import ROOT
import array

def main():
    inputfile  = sys.argv[1]
    outputfile = sys.argv[2]
    name   = sys.argv[3]
    weight = float(sys.argv[4])
    variations = sys.argv[5].split(',')

    if len(sys.argv) > 6:
        histtemplate = sys.argv[6]
    else:
        histtemplate = '{name}_{variation}'

    assert 'nominal' in variations


    fin = ROOT.TFile.Open(inputfile)
    ntin = fin.Get('ntuple;1')

    fout = ROOT.TFile.Open(outputfile,'RECREATE')

    hists = {}
    for v in variations:
        h = ROOT.TH1F(histtemplate.format(name = name,variation = v),'{}_{}'.format(name,v),50,-5,5)
        ROOT.SetOwnership( h, False )
        hists[v] = h
    for event in ntin:
        for v in variations:
            wname = 'weight_nominal' if v == 'nominal' else v
            hists[v].Fill(event.var,weight*getattr(event,wname) )

    for h in hists.values():
        h.Sumw2()
        h.Write()
    fout.Close()


if __name__ == '__main__':
    main()
