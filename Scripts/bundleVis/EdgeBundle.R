##main challenge is organizing the output from matlab into something sensible here.
#would like to use function networks as modules, + split up by left and right hemispheres
#(considering the results) that are mirrored across the connectogram.
#https://www.r-graph-gallery.com/309-intro-to-hierarchical-edge-bundling/
library(ggraph)
library(igraph)
library(RColorBrewer)
library(tidyverse)

# will get these to be passed as arguments as some stage...
deg = read.csv("/Users/luke/Documents/Projects/StrokeNet/Docs/Scripts/bundleVis/deg.csv", header = TRUE)
net = read.csv("/Users/luke/Documents/Projects/StrokeNet/Docs/Scripts/bundleVis/MAT.csv", header = TRUE)
att = read.csv("/Users/luke/Documents/Projects/StrokeNet/Docs/Scripts/bundleVis/H1.csv", header = TRUE)
att2 = read.csv("/Users/luke/Documents/Projects/StrokeNet/Docs/Scripts/bundleVis/H2.csv", header = TRUE)
hierarchy=rbind(att, att2)

# these are the node colours (change depending on parcellation, this is for )
# see http://www.stat.columbia.edu/~tzheng/files/Rcolor.pdf
att$to #in this order
colours = c("chartreuse3","chartreuse3",
            "firebrick1","firebrick1",
            "gold","gold",
            "aliceblue","aliceblue",
            "aquamarine2","aquamarine2",
            "coral","coral",
            "antiquewhite3","antiquewhite3",
            "deepskyblue3","deepskyblue3")

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
  geom_conn_bundle(data = get_con(from = from, to = to, value=connect$value), width=0.5, aes(colour=value),alpha = 0.1,tension = 0.9) +
  scale_edge_color_gradient2(low="skyblue",mid="white", high="red") +
  theme_void() +
  theme(legend.position = "none")

p + 
  geom_node_point(aes(filter = leaf, x = x*1.05, y=y*1.05, colour=group, size=value2, alpha=0.2)) +
  scale_colour_manual(values = colours) +
  scale_size_continuous( range = c(0.1,5) ) 
