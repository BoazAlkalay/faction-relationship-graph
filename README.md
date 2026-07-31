# Faction Relationship Graph

I DM a homebrew D&D campaign and kept losing track of who's in which noble
house, who's feuding with whom, and who secretly owes what to whom. This
started as a Quarto notebook full of `tidygraph` helper functions and grew
into a small Shiny app: add houses and NPCs, wire up relationships between
them, and see the whole thing as an interactive network graph instead of a
pile of notes.

The public demo runs on the real Padgett/Ansell Florentine families network
(16 houses of Renaissance Florence, their 20 documented marriage alliances,
and a handful of real historical figures with factual descriptions — see
`data/seed_data.R` for sourcing) — not my actual campaign. See "Using your
own data" below if you want to run it with real content that stays private.

## What it does

- Add houses and NPCs, with a name suggestion button — procedural fantasy names by default, or realistic names from a free external generator, by country (see the note below on both)
- Click a node on the graph to fill the From/To fields when adding a relationship, instead of hunting through the dropdowns
- Wire up relationships between them, with the type list auto-filtered to what actually makes sense between the two entities you pick
- Edit or delete any node/edge after the fact, including which attributes actually show up on hover
- Roll random personality trait / bond / flaw / ideal for an NPC
- Download the current graph as `.rds` and load it back later — the app itself has no persistence between sessions otherwise
- View the whole graph as an interactive `visNetwork` widget

## Structure

```
R/
  graph_core.R      # schemas + tbl_graph builder + generic rebuild_graph()
  node_functions.R  # add_house(), add_NPC(), update_node(), remove_node(), inspect_node(), full_name()
  edge_functions.R  # add_relationship(), NPC_assign_house(), add_NPC_relationship(),
                     # add_house_relations(), update_edge(), remove_edge()
  visualize.R       # make_visNetwork_graph(), tooltip formatting
  trait_roller.R    # roll_trait(), roll_all_traits(), load_custom_traits()
  name_roller.R     # roll_name(), roll_name_options(), roll_name_realistic()
  csv_io.R          # export_graph_csv(), load_graph_from_csv() - for migrating older data
data/
  seed_data.R       # build_seed_graph() - the placeholder demo world
app.R               # the Shiny app
```

## Node & edge types

- Nodes: `"house"`, `"NPC"`
- Edges: `member_house`, `NPC_NPC`, `house_house`, `NPC_house`

## Running it locally

```r
install.packages(c("shiny", "bslib", "tidyverse", "tidygraph", "igraph", "ggraph", "visNetwork"))
# optional, only needed for the "realistic name" generator:
install.packages("httr")
shiny::runApp()
```

## Deploying

- **shinyapps.io**: `rsconnect::deployApp()` from the project root. This
  needs the full live app, not a static export — adding nodes/edges and
  rolling traits happen server-side.
- **Linking from a static site**: a plain Quarto/GitHub Pages render can't
  host the interactive parts (that needs a running R process), so I just
  link out to the shinyapps.io URL from my site instead of trying to embed
  the whole app.

## Using your own (real) campaign data

I keep my actual campaign's data out of this repo. Two ways to work with
your own content, depending on where it's coming from:

**Ongoing work you build in the app itself:** use the **Save / Load** tab.
"Download current graph" saves everything to an `.rds` file; "Load" reads
one back in and replaces whatever's currently loaded. Keep that file
wherever you keep your campaign notes — it's not part of this repo.

**Migrating an older dataset** (e.g. built with an earlier version of this
project, or a messy edit history that's hard to replay cleanly): don't try
to re-run old code or load an old `.rds` directly — the schema has changed
since then. Instead, export the *current state* of the old graph object
(regardless of how it got there) and load it through the schema-reconciling
CSV path:

```r
# in the OLD project, wherever the graph object currently lives
nodes_df <- graph |> tidygraph::activate(nodes) |> tibble::as_tibble()
edges_df <- graph |> tidygraph::activate(edges) |> tibble::as_tibble()
readr::write_csv(nodes_df, "old_nodes.csv")
readr::write_csv(edges_df, "old_edges.csv")
```

Then use the **Save / Load** tab's "Load from CSV" option in this app, or
call `load_graph_from_csv("old_nodes.csv", "old_edges.csv")` directly — it
fills in any columns the current schema expects but the old export doesn't
have (e.g. `visible_fields`), and applies known column renames. Once it
loads correctly, use "Download current graph" to get an up-to-date `.rds`
you can reload directly from then on.

## On the trait/name tables

The personality trait / bond / flaw / ideal tables in `R/trait_roller.R`
are ones I wrote for this project, not transcribed from a published book —
that's on purpose, so this repo doesn't carry someone else's copyrighted
text.

`R/name_roller.R` has two modes:

- **Procedural** (`roll_name()`): builds names by recombining syllable
  fragments rather than pulling from a list — same idea as the trait
  tables, no external content involved.
- **Realistic** (`roll_name_realistic()`): calls the free, keyless
  [randomuser.me](https://randomuser.me) API for a real first+last name
  from a chosen country's naming pool. It's an existing name-generation
  service, not a generative model — needs internet and the `httr`
  package. Good for NPCs where "sounds like a plausible person" matters
  more than fantasy flavor.

If you'd rather use your own curated name/trait tables, load a CSV the
same way `trait_roller.R`'s `load_custom_traits()` does, and credit the
source here rather than pasting the original text into the repo.
