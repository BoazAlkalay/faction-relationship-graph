# seed_data.R
#
# Demo world for the public app and website widget: the Padgett/Ansell
# Florentine families network plus real historical figures, same as before -
# but now loaded from data/florentine_nodes.csv and data/florentine_edges.csv
# instead of being hand-written here, so it can grow as you research more
# people from the book without editing code each time.
#
# To refresh these CSVs after adding people/relationships (via the running
# app, or by hand), from the project root:
#
#   source("R/graph_core.R"); source("R/node_functions.R")
#   source("R/edge_functions.R"); source("R/csv_io.R")
#   g <- readRDS("data/your-checkpoint.rds")  # or however you have it loaded
#   export_graph_csv(g, "data/florentine_nodes.csv", "data/florentine_edges.csv")
#
# These CSVs are real historical/factual content, not private campaign data,
# so unlike torin_*.csv they ARE meant to be committed to the repo.

build_seed_graph <- function() {
  load_graph_from_csv("data/florentine_nodes.csv", "data/florentine_edges.csv")
}
