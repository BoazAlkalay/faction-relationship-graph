# Noble Houses Graph Tool

A small toolkit for modeling D&D noble houses, NPCs, and their relationships
as a graph — built on `tidygraph` / `igraph`, viewed with `visNetwork`, and
wrapped in a Shiny app so you (or players) can add houses/NPCs, wire up
relationships, and roll random personality traits without touching code.

The public demo runs on a **fully fictional placeholder world** (`data/seed_data.R`),
not any real campaign — see "Using your own data" below.

## Structure

```
R/
  graph_core.R      # schemas + tbl_graph builder + generic rebuild_graph()
  node_functions.R  # add_house(), add_NPC(), update_node(), remove_node(), inspect_node(), full_name()
  edge_functions.R  # add_relationship(), NPC_assign_house(), add_NPC_relationship(),
                     # add_house_relations(), update_edge(), remove_edge()
  visualize.R       # make_visNetwork_graph(), tooltip formatting
  trait_roller.R    # roll_trait(), roll_all_traits(), load_custom_traits()
data/
  seed_data.R       # build_seed_graph() - fictional demo world
app.R               # the Shiny app
```

## Node & edge types

- Nodes: `"house"`, `"NPC"`
- Edges: `member_house`, `NPC_NPC`, `house_house`, `NPC_house`

## Running locally

```r
install.packages(c("shiny", "tidyverse", "tidygraph", "igraph", "ggraph", "visNetwork"))
shiny::runApp()
```

## Deploying

- **shinyapps.io**: `rsconnect::deployApp()` from the project root — this needs
  the full app (it's not a static site, since adding nodes/edges and rolling
  traits happen server-side).
- **Embedding in a Quarto/GitHub Pages site**: link out to the shinyapps.io
  URL, or embed it in an iframe on a page in your site. A pure static Quarto
  render can't host the "add a node" / "roll traits" interactivity — that
  needs a live R process.

## Using your own (real) campaign data

Don't edit `data/seed_data.R` in place if you want to keep your own graph
private. Instead:

1. Write your own `data/my_seed_data.R` with a `build_seed_graph()` function
   (same shape as the demo one, but with your real houses/NPCs/edges).
2. In `app.R`, swap the `source("data/seed_data.R")` line for your file.
3. Add that file to `.gitignore` so it never gets committed:
   ```
   data/my_seed_data.R
   ```

This keeps the public repo/app showing only the placeholder world while your
own graph stays local.

## Trait tables

`R/trait_roller.R` ships with a small set of **original** personality
trait / bond / flaw / ideal tables written for this project — nothing
transcribed from a published sourcebook. If you'd rather roll on tables
from a book you own, write your own CSV (`category,text` columns) and load
it with `load_custom_traits("path/to/your.csv")`, then credit the source
in this README rather than pasting its text into the repo.
