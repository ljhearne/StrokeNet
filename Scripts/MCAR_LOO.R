# http://www.sthda.com/english/articles/31-principal-component-methods-in-r-practical-guide/114-mca-multiple-correspondence-analysis-in-r-essentials/
# this is code to perform MCA on binarized lesion data

rm(list=ls())

library("FactoMineR")
library("factoextra")

# HARDCODED VARIABLES------------#
# have not found a sensible way of calling R from matlab with variables...

IN = "/Users/luke/Documents/Projects/StrokeNet/Data/MCA/MCAinput.csv"
IN2 ="/Users/luke/Documents/Projects/StrokeNet/Data/MCA/MCAcomp.csv"
OUT= "/Users/luke/Documents/Projects/StrokeNet/Data/MCA/"
# -------------------------------#

#------------------------------------------------------------
comps = read.csv(IN2)
data = read.csv(IN, header = FALSE)
data = data.frame(lapply(data, as.factor)) #convert data
print('data loaded')

start.time <- Sys.time()
result = MCA(data,ncp = comps[2], graph = FALSE) #do the MCA
print('Initial MCA finished')
end.time <- Sys.time()
time.taken <- end.time - start.time
time.taken

#------------------------------------------------------------
n_sub = dim(data[1])

for (sub in c(1:n_sub)){
  print(paste("Running LOO for",sub))
  
  left_out = result$call$X[sub,]
  left_in  = data[-c(sub), ]
  
  #re run the MCA
  LOO_result = MCA(left_in,ncp = comps[2], graph = FALSE) #do the MCA
  
  #predict the left out
  LOO_left_out_result = predict.MCA(LOO_result,left_out)
  
  IND = get_mca_ind(LOO_result) # get individual weights
  write.csv(IND$coord, file = paste(OUT,"MCA_IndWeights_LO",sub,".csv",sep=""))
  write.csv(LOO_left_out_result$coord, file = paste(OUT,"MCA_LO",sub,"_vec.csv",sep=""))
  
  VAR = get_mca_var(LOO_result) # get variable (connection) weights
  write.csv(VAR$coord, file = paste(OUT,"MCA_VarWeights_LO",sub,".csv",sep=""))
  
  eig.val = get_eigenvalue(LOO_result) #get variance explained
  write.csv(eig.val, file = paste(OUT,"MCA_Eigenvalues_LO",sub,".csv",sep=""))
}
