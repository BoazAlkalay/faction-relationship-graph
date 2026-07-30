# csv_io.R
# Import/export helpers - mainly for migrating a graph built under an older
# version of this project (different column set) into the current schema
# without having to replay the whole edit history that produced it.

#' Export a graph's nodes/edges to two CSVs (round-trips with load_graph_from_csv()).
export_graph_csv <- function(graph, nodes_path, edges_path) {
  nodes_df <- graph |> activate(nodes) |> as_tibble()
  edges_df <- graph |> activate(edges) |> as_tibble()
  readr::write_csv(nodes_df, nodes_path)
  readr::write_csv(edges_df, edges_path)
}

#' Load a graph from two CSVs (nodes + edges), reconciling them against the
#' current house_schema/npc_schema/edge_schema - any column the current
#' schema expects but the CSV doesn't have gets added as NA, and any extra
#' columns in the CSV are kept rather than silently dropped. `from`/`to` in
#' the edges CSV are assumed to be the same row-number ids as in the nodes
#' CSV (true if both were exported together via export_graph_csv()).
load_graph_from_csv <- function(nodes_path, edges_path) {
  nodes_raw <- readr::read_csv(nodes_path, show_col_types = FALSE)
  edges_raw <- readr::read_csv(edges_path, show_col_types = FALSE)

  expected_node_cols <- union(names(house_schema), names(npc_schema))
  for (col in setdiff(expected_node_cols, names(nodes_raw))) {
    nodes_raw[[col]] <- NA
  }

  # Known legacy -> current column renames go here as you find them.
  legacy_renames <- c(industry_moder = "industry_modern")
  for (old_name in names(legacy_renames)) {
    new_name <- legacy_renames[[old_name]]
    if (old_name %in% names(nodes_raw) && !new_name %in% names(nodes_raw)) {
      nodes_raw[[new_name]] <- nodes_raw[[old_name]]
      nodes_raw[[old_name]] <- NULL
    }
  }

  expected_edge_cols <- c("from", "to", "edge_type", names(edge_schema))
  for (col in setdiff(expected_edge_cols, names(edges_raw))) {
    edges_raw[[col]] <- NA
  }

  tbl_graph(nodes = nodes_raw, edges = edges_raw)
}
