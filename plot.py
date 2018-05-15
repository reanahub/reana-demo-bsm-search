import sys
import ROOT

def main():
    inputfilename = sys.argv[1]
    plotfile = sys.argv[2]

    f_merged = ROOT.TFile.Open(inputfilename)

    mc1 = f_merged.Get('mc1_nominal;1')
    mc1.SetFillColor(ROOT.kRed)

    mc2 = f_merged.Get('mc2_nominal;1')
    mc2.SetFillColor(ROOT.kGreen)

    # allmc = 
    qcd   = f_merged.Get('qcd_nominal;1')
    qcd.SetFillColor(ROOT.kBlue)

    data  = f_merged.Get('data_nominal;1')

    c = ROOT.TCanvas()

    stack = ROOT.THStack()
    stack.Add(qcd)
    stack.Add(mc1)
    stack.Add(mc2)

    stack.Draw('hist')


    data.SetMarkerStyle(20)
    data.SetLineColor(ROOT.kBlack)
    data.Draw('E1same')

    c.SaveAs(plotfile)

if __name__ == '__main__':
    main()
