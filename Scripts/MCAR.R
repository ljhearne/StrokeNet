# http://www.sthda.com/english/articles/31-principal-component-methods-in-r-practical-guide/114-mca-multiple-correspondence-analysis-in-r-essentials/
# this is code to perform MCA on binarized lesion data

rm(list=ls())

library("FactoMineR")
library("factoextra")

# HARDCODED VARIABLES------------#
# have not found a sensible way of calling R from matlab with variables...
#IN = "/projects/sw49/Results/MCA/MCAinput.csv"
#IN2 = '/projects/sw49/Results/MCA/MCAcomp.csv'
#OUT= "/projects/sw49/Results/MCA/"

IN = "/Users/luke/Documents/Projects/StrokeNet/Docs/Results/MCA/MCAinput.csv"
IN2 = '/Users/luke/Documents/Projects/StrokeNet/Docs/Results/MCA/MCAcomp.csv'
OUT= "/Users/luke/Documents/Projects/StrokeNet/Docs/Results/MCA/"
# -------------------------------#

#------------------------------------------------------------
comps = read.csv(IN2)
data = read.csv(IN, header = FALSE)
data = data.frame(lapply(data, as.factor)) #convert data
print('data loaded')

result = MCA(data,ncp = comps[2], graph = FALSE) #do the MCA
print('MCA finished')

IND = get_mca_ind(result) # get individual weights
write.csv(IND$coord, file = paste(OUT,"MCA_IndWeights.csv",sep=""))

VAR = get_mca_var(result) # get variable (connection) weights
write.csv(VAR$coord, file = paste(OUT,"MCA_VarWeights.csv",sep=""))

eig.val = get_eigenvalue(result) #get variance explained
write.csv(eig.val, file = paste(OUT,"MCA_Eigenvalues.csv",sep=""))
#------------------------------------------------------------
