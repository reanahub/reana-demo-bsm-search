import sys
import ROOT
import array
import random


def apply_shape(var,shape_name):
    if shape_name == 'shape_conv_up':
        shift = random.uniform(0,1.0) 
        return var + shift
    if shape_name == 'shape_conv_dn':
        shift = random.uniform(-1.0,0) 
        return var + shift
    raise RuntimeError('unknown shape variation')

def calc_weight(var,weight_name):
    if weight_name == 'weight_var1_up':
        return 1.05
    if weight_name == 'weight_var1_dn':
        return 0.95
    raise RuntimeError('unknown weight variation')

def main():
    inputfile       = sys.argv[1]
    outputfile      = sys.argv[2]
    selection       = sys.argv[3]
    variations      = sys.argv[4].split(',')


    shape_vars =  [x for x in variations if 'shape_' in x]
    weight_vars = [x for x in variations if 'weight_' in x]

    nominal = 'nominal' in variations
    if (nominal or weight_vars) and shape_vars:
        print('cannnot run shape variations together with nominal or weight variations')
        return 1        ,

    if (weight_vars and not nominal):
        print('need to run nominal in order to run weight variations')

    if len(shape_vars) > 1:
        print('shape vars must be run one at a time')
        return 1        ,

    fin = ROOT.TFile.Open(inputfile)
    ntin = fin.Get('ntuple;1')

    fout = ROOT.TFile.Open(outputfile,'RECREATE')
    varlist = 'region:var:weight_nominal'
    if weight_vars:
        varlist = varlist + ':' + ':'.join(weight_vars)
    print(varlist)
    ntout= ROOT.TNtuple('ntuple','ntuple',varlist)
    ROOT.SetOwnership( ntout, False )


    for event in ntin:
        region, var = event.region, event.var

        if shape_vars:
            var = apply_shape(var, shape_vars[0])

        weights = [1.0] + [calc_weight(var,weightname)  for weightname in weight_vars]
        if selection == 'signal':
            if not (region == 1.0 and -5 < var < 5):
                continue

        if selection == 'control':
            if not (region == 0.0 and -5 < var < 5):
                continue

        a = array.array('f')
        a.fromlist([region,var] + weights)
        ntout.Fill(a)

    ntout.Write()
    fout.Close()



if __name__ == '__main__':
    main()