# graph_core.R
# Core tbl_graph construction and the generic rebuild helper that all
# add_* functions rely on.

library(tidyverse)
library(tidygraph)

# Canonical column schemas. Keeping these as named lists (rather than
# repeating NA_character_ defaults inside every add_* function, like the
# original draft did) means there is exactly one place to add/remove a
# tracked attribute.

house_schema <- list(
  node_type = "house",
  # Which attributes show up in the graph tooltip - comma-separated field
  # names. Editable per-house via the Edit/Delete tab; doesn't affect
  # inspect_node(), which always shows everything filled in.
  visible_fields = "desc,city",
  # Identity & Location
  desc = NA_character_,
  history = NA_character_,
  crest_desc = NA_character_,
  city = NA_character_,
  district = NA_character_,
  seat_of_power = NA_character_,
  # Economic Foundation
  industry_hist = NA_character_,
  industry_modern = NA_character_,
  holdings = NA_character_,
  wealth = NA_character_,
  # Power & Influence
  influence = NA_character_,
  church_standing = NA_character_,
  military_obligations = NA_character_,
  guild_affiliations = NA_character_,
  banking_or_credit_networks = NA_character_,
  # Culture & Legacy
  notable_ancestors = NA_character_,
  artistic_patronage = NA_character_,
  # Goals & Drama
  goals_n_interests = NA_character_,
  scandals = NA_character_,
  secrets = NA_character_
)

npc_schema <- list(
  node_type = "NPC",
  # Which attributes show up in the graph tooltip - see house_schema note above.
  visible_fields = "personality_trait,bond,flaw,ideal,desc,age,birth_year,death_year",
  # Character traits (see trait_roller.R) - kept up top since these are
  # usually the first thing worth glancing at for an NPC
  personality_trait = NA_character_,
  bond = NA_character_,
  flaw = NA_character_,
  ideal = NA_character_,
  # Dates - free text (not parsed) so "c. 1421" or "unknown" work fine, not
  # just clean numbers
  birth_year = NA_character_,
  death_year = NA_character_,
  # Identity & Location
  age = NA_integer_,
  desc = NA_character_,
  history = NA_character_,
  city = NA_character_,
  district = NA_character_,
  main_residence = NA_character_,
  # Status & Position
  title_position = NA_character_,
  legitimacy_status = NA_character_,   # "legitimate" | "bastard" | "legitimized"
  reputation = NA_character_,
  popularity = NA_character_,
  guild_o_church_connections = NA_character_,
  # Capabilities & Resources
  education = NA_character_,
  magical_n_combat_prowess = NA_character_,
  CR = NA_integer_,
  statblock = NA_character_,
  wealth = NA_character_,
  items_of_interest = NA_character_,
  # Motivations & Drama
  relation_to_PCs = NA_character_,
  goals_n_interests = NA_character_,
  scandals = NA_character_,
  secrets = NA_character_
)

edge_schema <- list(
  relationship_nature = NA_character_,
  date = NA_character_,  # e.g. "1415" or "26 April 1478" - free text, not parsed
  sentiment = NA_character_,
  standing = NA_character_,
  intentions = NA_character_,
  position = NA_character_,
  geographic_scope = NA_character_,
  additional_desc = NA_character_
)

edge_labels <- c(
  "house_house"  = "House Relationship",
  "NPC_NPC"      = "Personal Relationship",
  "member_house" = "House Membership",
  "NPC_house"    = "Affiliation Between Non-member and House"
)

#' Build an empty graph with the right columns already present, so
#' rbind-ing new rows never has to guess about missing columns.
new_empty_graph <- function() {
  nodes <- bind_rows(
    as_tibble(house_schema)[0, ],
    as_tibble(npc_schema)[0, ]
  ) |>
    mutate(name = character(), .before = 1)

  edges <- as_tibble(edge_schema)[0, ] |>
    mutate(from = integer(), to = integer(), edge_type = character(),
           .before = 1)

  tbl_graph(nodes = nodes, edges = edges)
}

#' Append a new node or edge tibble to a graph and rebuild it.
#' n_or_e: one of "n"/"node"/"v"/"vertex" or anything else (treated as edge)
rebuild_graph <- function(graph, n_or_e, new_rows) {
  cur_nodes <- graph |> activate(nodes) |> as_tibble()
  cur_edges <- graph |> activate(edges) |> as_tibble()

  if (n_or_e %in% c("n", "node", "v", "vertex")) {
    cur_nodes <- bind_rows(cur_nodes, new_rows)
  } else {
    cur_edges <- bind_rows(cur_edges, new_rows)
  }

  tbl_graph(nodes = cur_nodes, edges = cur_edges)
}
