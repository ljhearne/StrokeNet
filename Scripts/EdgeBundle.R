##main challenge is organizing the output from matlab into something sensible here.
#would like to use function networks as modules, + split up by left and right hemispheres
#(considering the results) that are mirrored across the connectogram.
#https://www.r-graph-gallery.com/309-intro-to-hierarchical-edge-bundling/

library(ggraph)
library(igraph)
library(RColorBrewer)
library(tidyverse)

args = commandArgs(trailingOnly=TRUE)

deg = read.csv(args[1], header = TRUE)
net = read.csv(args[2], header = TRUE)
att = read.csv(args[3], header = TRUE)
att2 = read.csv(args[4], header = TRUE)
out = args[5]
print(out)

hierarchy=rbind(att, att2)

# these are the node colours (WILL CHANGE DEPENDING ON PARCELLATION)
# see http://www.stat.columbia.edu/~tzheng/files/Rcolor.pdf
colours = c("black","bisque4","firebrick","darkgoldenrod1","aliceblue","darkcyan","darkseagreen3","darksalmon","cornflowerblue")
#basic cols
#colours = c("black","brown","red","gold","aliceblue","purple","green","orange","blue")

# create a vertices data.frame. One line per object of our hierarchy
vertices = data.frame(name = unique(c(as.character(hierarchy$from), as.character(hierarchy$to))) ) 

# Let's add a column with the group of each name. It will be useful later to color points
vertices$group = hierarchy$from[ match( vertices$name, hierarchy$to ) ]
DEG = 0.01
DEG[1:(length(vertices$group)-length(deg))] = 0.01
DEG[(length(DEG)+1):(length(vertices$group))] = deg
DEG = as.numeric(DEG)
vertices$value2 = DEG

# Create a graph object with the igraph library

mygraph <- graph_from_data_frame(hierarchy, vertices=vertices )
plot(mygraph, vertex.label="", edge.arrow.size=0, vertex.size=2)

# create a dataframe with connection between leaves (nodes)
all_leaves = levels(att2$to)[as.numeric(att2$to)]

connect=net

# The connection object must refer to the ids of the leaves:
from = match( connect$from, vertices$name)
to = match( connect$to, vertices$name)

# plot
p = ggraph(mygraph, layout = 'dendrogram', circular = TRUE) + 
  geom_conn_bundle(data = get_con(from = from, to = to, value=connect$value), width=0.5, aes(colour=value),alpha = 0.25,tension = 0.9) +
  scale_edge_color_gradient2(low="skyblue",mid="white", high="red") +
  theme_void() +
  theme(legend.position = "none")

p + 
  geom_node_point(aes(filter = leaf, x = x*1.05, y=y*1.05, colour=group, size=value2, alpha=0.2), show.legend = TRUE) +
  scale_colour_manual(values = colours) +
  scale_size_continuous( range = c(0.1,20))
  
ggsave(out, width = 5, height = 5,dpi = 600, limitsize = FALSE)

#INdeg = "/Users/luke/Documents/Projects/StrokeNet/Docs/Results/CCA/Mode1thresh1000_deg.csv"
#INnet = "/Users/luke/Documents/Projects/StrokeNet/Docs/Results/CCA/Mode1thresh1000_MAT.csv"
#INatt = "/Users/luke/Documents/Projects/StrokeNet/Docs/Results/CCA/Mode1thresh1000_Bundle1.csv"
#INatt2 = "/Users/luke/Documents/Projects/StrokeNet/Docs/Results/CCA/Mode1thresh1000_Bundle2.csv"
#out = '/Users/luke/Desktop/test.pdf'
#EdgeBundle(Indeg,Innet,Inatt,Inatt2,out)