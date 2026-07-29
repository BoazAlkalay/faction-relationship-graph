# edge_functions.R
# Requires graph_core.R and node_functions.R to be sourced first.

#' Generic edge add by node names + an explicit edge_type. Most callers
#' will prefer the type-specific helpers below, which set sensible
#' defaults for edge_type and required fields.
add_relationship <- function(graph, from_name, to_name, edge_type, ...) {
  from_id <- .node_id(graph, from_name, "Node")
  to_id   <- .node_id(graph, to_name, "Node")

  new_edge <- modifyList(edge_schema, list(
    from = from_id, to = to_id, edge_type = edge_type, ...
  )) |> as_tibble()

  rebuild_graph(graph, "edge", new_edge)
}

#' Connect an NPC to the house they are a member of.
#' @param position e.g. "Head of Household", "Heir, first in line"
#' @param sentiment How the NPC feels about their house
#' @param standing Are they in the good graces of their HoH / house at large?
NPC_assign_house <- function(graph, npc, house, position = NA_character_, ...) {
  npc_id   <- .node_id(graph, npc, "NPC")
  house_id <- .node_id(graph, house, "House")

  new_edge <- modifyList(edge_schema, list(
    from = npc_id, to = house_id,
    edge_type = "member_house",
    relationship_nature = "by birth",
    position = position,
    ...
  )) |> as_tibble()

  rebuild_graph(graph, "edge", new_edge)
}

#' Add a relationship between two NPCs.
#' @param relationship_nature type as seen from from_NPC's side (e.g. "sibling")
#' @param sentiment feeling of from_NPC about to_NPC
#' @param mutual if TRUE, also creates the reverse edge
add_NPC_relationship <- function(graph, from_NPC, to_NPC, relationship_nature,
                                  sentiment = NA_character_, mutual = FALSE, ...) {
  from_id <- .node_id(graph, from_NPC, "NPC")
  to_id   <- .node_id(graph, to_NPC, "NPC")

  new_edge <- modifyList(edge_schema, list(
    from = from_id, to = to_id,
    edge_type = "NPC_NPC",
    relationship_nature = relationship_nature,
    sentiment = sentiment,
    ...
  )) |> as_tibble()

  if (mutual) {
    reverse_edge <- modifyList(edge_schema, list(
      from = to_id, to = from_id,
      edge_type = "NPC_NPC",
      relationship_nature = relationship_nature,
      ...
    )) |> as_tibble()
    new_edge <- bind_rows(new_edge, reverse_edge)
  }

  rebuild_graph(graph, "edge", new_edge)
}

#' Add a relationship between two houses.
#' @param standing How these houses view each other (ally/rival/neutral)
#' @param mutual defaults TRUE since house-to-house standing is usually symmetric
add_house_relations <- function(graph, from_name, to_name,
                                 standing = NA_character_, mutual = TRUE, ...) {
  from_id <- .node_id(graph, from_name, "House")
  to_id   <- .node_id(graph, to_name, "House")

  new_edge <- modifyList(edge_schema, list(
    from = from_id, to = to_id,
    edge_type = "house_house",
    standing = standing,
    ...
  )) |> as_tibble()

  if (mutual) {
    reverse_edge <- modifyList(edge_schema, list(
      from = to_id, to = from_id,
      edge_type = "house_house",
      standing = standing,
      ...
    )) |> as_tibble()
    new_edge <- bind_rows(new_edge, reverse_edge)
  }

  rebuild_graph(graph, "edge", new_edge)
}

#' Update one or more attributes of an existing edge.
update_edge <- function(graph, sending, receiving, ...) {
  updates <- list(...)
  from_id <- .node_id(graph, sending, "Sending node")
  to_id   <- .node_id(graph, receiving, "Receiving node")

  cur_nodes <- graph |> activate(nodes) |> as_tibble()
  cur_edges <- graph |> activate(edges) |> as_tibble()

  edge_id <- which(cur_edges$from == from_id & cur_edges$to == to_id)
  if (length(edge_id) == 0) {
    stop(paste("Edge not found from", sending, "to", receiving))
  }

  for (attr in names(updates)) {
    cur_edges[edge_id, attr] <- updates[[attr]]
  }

  tbl_graph(nodes = cur_nodes, edges = cur_edges)
}

#' Remove an edge by its endpoint names.
remove_edge <- function(graph, from_name, to_name) {
  graph |>
    activate(edges) |>
    filter(!(.N()$name[from] == from_name & .N()$name[to] == to_name))
}
