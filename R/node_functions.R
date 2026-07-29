# node_functions.R
# Requires graph_core.R to be sourced first (house_schema, npc_schema, etc.)

.node_exists <- function(graph, name) {
  nodes <- graph |> activate(nodes) |> as_tibble()
  length(which(nodes$name == name)) > 0
}

.node_id <- function(graph, name, label = "Node") {
  nodes <- graph |> activate(nodes) |> as_tibble()
  id <- which(nodes$name == name)
  if (length(id) == 0) stop(paste(label, "not found:", name))
  id
}

#' Add a house to the graph.
add_house <- function(graph, name, ...) {
  if (.node_exists(graph, name)) {
    stop(paste0("House ", name, " already exists, try update_node() instead!"))
  }
  new_house <- modifyList(house_schema, list(name = name, ...)) |> as_tibble()
  rebuild_graph(graph, "node", new_house)
}

#' Add an NPC to the graph.
add_NPC <- function(graph, name, ...) {
  if (.node_exists(graph, name)) {
    stop(paste0("NPC ", name, " already exists, try update_node() instead!"))
  }
  new_npc <- modifyList(npc_schema, list(name = name, ...)) |> as_tibble()
  rebuild_graph(graph, "node", new_npc)
}

#' Update one or more attributes of an existing node by name.
update_node <- function(graph, node_name, ...) {
  updates <- list(...)
  id <- .node_id(graph, node_name, "Node")

  cur_nodes <- graph |> activate(nodes) |> as_tibble()
  cur_edges <- graph |> activate(edges) |> as_tibble()

  for (attr in names(updates)) {
    cur_nodes[id, attr] <- updates[[attr]]
  }

  tbl_graph(nodes = cur_nodes, edges = cur_edges)
}

#' Remove a node (and, automatically, every edge touching it).
remove_node <- function(graph, node_name) {
  graph |> activate(nodes) |> filter(name != node_name)
}

#' Return a node's non-empty attributes as a tidy (Attribute, Value) table.
#' Useful both in the console and for rendering a Shiny "detail card".
inspect_node <- function(graph, node_name, preview_length = 100) {
  graph |>
    activate(nodes) |>
    as_tibble() |>
    filter(name == node_name) |>
    pivot_longer(
      cols = everything(),
      names_to = "Attribute",
      values_to = "Value",
      values_transform = as.character
    ) |>
    filter(!is.na(Value) & Value != "") |>
    mutate(
      Preview = str_trunc(Value, preview_length),
      Full_Text = Value
    ) |>
    select(Attribute, Preview, Full_Text)
}

#' Build a display name for an NPC by appending the house(s) they belong to,
#' e.g. full_name(g, "Martious") -> "Martious Birnathus"
full_name <- function(graph, node_name) {
  nodes <- graph |> activate(nodes) |> as_tibble()
  id <- .node_id(graph, node_name, "Node")

  house_ids <- graph |>
    activate(edges) |>
    as_tibble() |>
    filter(from == id, edge_type == "member_house") |>
    pull(to)

  house_names <- nodes$name[house_ids]
  paste(trimws(paste(node_name, paste(house_names, collapse = " "))))
}
