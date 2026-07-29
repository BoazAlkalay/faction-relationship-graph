# seed_data.R
#
# Small, fully fictional demo world used for the public app. None of this
# is the maintainer's real campaign data — it exists purely to show the
# tool's shape (a few houses, a few NPCs, one example of each edge type).
# Swap this file out for your own build_seed_graph() to run your own game.

build_seed_graph <- function() {
  g <- new_empty_graph()

  # --- Houses ---------------------------------------------------------
  g <- g |>
    add_house("Voss", city = "Aldenmere", desc = "Old shipping money, now mostly reputation.") |>
    add_house("Rourke", city = "Aldenmere", desc = "Rose fast on mercenary contracts, resented for it.") |>
    add_house("Castellan", city = "Aldenmere", desc = "Runs the city's banking guild in all but name.")

  g <- g |> add_house_relations("Voss", "Rourke", standing = "Rival")
  g <- g |> add_house_relations("Rourke", "Castellan", standing = "Ally")

  # --- NPCs -------------------------------------------------------------
  g <- g |>
    add_NPC("Isolde Voss", age = 41, title_position = "Head of Household",
            desc = "Sharp, controlled, plays a long game.") |>
    add_NPC("Bram Voss", age = 19, title_position = "Heir",
            desc = "Wants out from under his mother's shadow.") |>
    add_NPC("Kell Rourke", age = 52, title_position = "Head of Household",
            desc = "Built the house from nothing and never lets anyone forget it.") |>
    add_NPC("Dessa Castellan", age = 35, title_position = "Guildmaster",
            desc = "Knows where every debt in the city is buried.")

  # Roll traits for each NPC so the demo shows the roller in action
  for (npc in c("Isolde Voss", "Bram Voss", "Kell Rourke", "Dessa Castellan")) {
    traits <- roll_all_traits()
    g <- do.call(update_node, c(list(graph = g, node_name = npc), traits))
  }

  # --- Memberships --------------------------------------------------
  g <- g |> NPC_assign_house("Isolde Voss", "Voss", position = "Head of Household")
  g <- g |> NPC_assign_house("Bram Voss", "Voss", position = "Heir, first in line",
                              sentiment = "Resentful but dutiful")
  g <- g |> NPC_assign_house("Kell Rourke", "Rourke", position = "Head of Household")
  g <- g |> NPC_assign_house("Dessa Castellan", "Castellan", position = "Guildmaster")

  # --- Personal relationships ----------------------------------------
  g <- g |> add_NPC_relationship(
    "Bram Voss", "Isolde Voss", relationship_nature = "child",
    sentiment = "Wants her approval and resents needing it", mutual = FALSE
  )
  g <- g |> add_NPC_relationship(
    "Kell Rourke", "Dessa Castellan", relationship_nature = "old allies",
    sentiment = "Trusts her more than his own kin", mutual = TRUE
  )

  # --- Cross-house affiliation (NPC_house) -----------------------------
  g <- g |> add_relationship(
    "Dessa Castellan", "Voss", edge_type = "NPC_house",
    relationship_nature = "creditor", standing = "watched carefully",
    additional_desc = "Holds a loan against the Voss shipping fleet."
  )

  g
}
