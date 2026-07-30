# csv_io.R
# Import/export helpers - mainly for migrating a graph built under an older
# version of this project (different column set, or a messy edit history
# that left behind a few duplicate/typo'd columns) into the current schema,
# without having to replay whatever code produced it.

#' Export a graph's nodes/edges to two CSVs (round-trips with load_graph_from_csv()).
export_graph_csv <- function(graph, nodes_path, edges_path) {
  nodes_df <- graph |> activate(nodes) |> as_tibble()
  edges_df <- graph |> activate(edges) |> as_tibble()
  readr::write_csv(nodes_df, nodes_path)
  readr::write_csv(edges_df, edges_path)
}

# Prefer the first non-NA/non-empty value between two columns of the same tibble.
.coalesce_cols <- function(df, keep, drop) {
  if (!drop %in% names(df)) return(df)
  if (!keep %in% names(df)) {
    names(df)[names(df) == drop] <- keep
    return(df)
  }
  keep_val <- df[[keep]]
  drop_val <- df[[drop]]
  use_drop <- (is.na(keep_val) | keep_val == "") & !is.na(drop_val) & drop_val != ""
  keep_val[use_drop] <- drop_val[use_drop]
  df[[keep]] <- keep_val
  df[[drop]] <- NULL
  df
}

#' Load a graph from two CSVs (nodes + edges), reconciling them against the
#' current house_schema/npc_schema/edge_schema:
#' - missing expected columns are added as NA
#' - known legacy/typo'd column names are merged into their correct column
#'   (case-mismatches like "Position"/"position", and specific renames like
#'   "industry_moder" -> "industry_modern", "magic_n_combat_prowess" ->
#'   "magical_n_combat_prowess")
#' - a stray node-level "position" column (a mix-up with the edge-level
#'   membership position) gets folded into title_position instead of lost
#' - anything left over that doesn't map to a known column is kept, but
#'   reported via message() so it doesn't quietly go unnoticed
load_graph_from_csv <- function(nodes_path, edges_path) {
  nodes_raw <- readr::read_csv(nodes_path, show_col_types = FALSE)
  edges_raw <- readr::read_csv(edges_path, show_col_types = FALSE)

  # --- Nodes: known fixes -------------------------------------------------
  if ("id" %in% names(nodes_raw)) {
    message("Dropping leftover 'id' column on nodes (stale row numbers from an earlier build step).")
    nodes_raw[["id"]] <- NULL
  }

  nodes_raw <- .coalesce_cols(nodes_raw, "industry_modern", "industry_moder")
  nodes_raw <- .coalesce_cols(nodes_raw, "magical_n_combat_prowess", "magic_n_combat_prowess")

  if ("position" %in% names(nodes_raw)) {
    message("Found a node-level 'position' column - folding any values into title_position (it belongs on the membership edge, not the node).")
    nodes_raw <- .coalesce_cols(nodes_raw, "title_position", "position")
  }

  expected_node_cols <- union(names(house_schema), names(npc_schema))
  for (col in setdiff(expected_node_cols, names(nodes_raw))) {
    nodes_raw[[col]] <- NA
  }

  leftover_node_cols <- setdiff(names(nodes_raw), c("name", expected_node_cols))
  if (length(leftover_node_cols) > 0) {
    message("Nodes CSV has columns not in the current schema (kept, but won't show in the app's editor): ",
            paste(leftover_node_cols, collapse = ", "))
  }

  # --- Edges: known fixes --------------------------------------------------
  edges_raw <- .coalesce_cols(edges_raw, "position", "Position")

  if ("mutal" %in% names(edges_raw)) {
    one_sided <- edges_raw[!is.na(edges_raw$mutal) & edges_raw$mutal != "", ]
    if (nrow(one_sided) > 0) {
      message("Found ", nrow(one_sided), " edge(s) with a 'mutal' column (likely a typo for the ",
              "mutual= argument) - the reverse tie may never have been created. Check these from/to pairs: ",
              paste(paste0(one_sided$from, "->", one_sided$to), collapse = ", "))
    }
    edges_raw[["mutal"]] <- NULL
  }

  expected_edge_cols <- c("from", "to", "edge_type", names(edge_schema))
  for (col in setdiff(expected_edge_cols, names(edges_raw))) {
    edges_raw[[col]] <- NA
  }

  leftover_edge_cols <- setdiff(names(edges_raw), expected_edge_cols)
  if (length(leftover_edge_cols) > 0) {
    message("Edges CSV has columns not in the current schema (kept, but won't show in the app's editor): ",
            paste(leftover_edge_cols, collapse = ", "))
  }

  tbl_graph(nodes = nodes_raw, edges = edges_raw)
}
