source("R/graph_core.R")
source("R/node_functions.R")
source("R/edge_functions.R")
source("R/visualize.R")
source("data/seed_data.R")

g <- build_seed_graph()
widget <- make_visNetwork_graph(g)

htmlwidgets::saveWidget(widget, "faction-graph-demo.html", selfcontained = TRUE)
