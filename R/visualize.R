# visualize.R
# Requires graph_core.R sourced first (for edge_labels).

library(visNetwork)

#' Vectorized "Field: value<br>" formatter for tooltips. Blank/NA fields
#' collapse to "" so tooltips don't show a wall of "Field: NA".
format_tooltip_field <- function(field_name, field_value, max_chars = NULL) {
  ifelse(
    is.na(field_value) | field_value == "",
    "",
    {
      truncated <- if (!is.null(max_chars)) {
        ifelse(nchar(field_value) > max_chars,
               paste0(substr(field_value, 1, max_chars), "..."),
               field_value)
      } else {
        field_value
      }
      formatted <- gsub("\n", "<br>", truncated)
      paste0(field_name, ": ", formatted, "<br>")
    }
  )
}

#' Build one node's tooltip HTML from whichever fields its visible_fields
#' column lists (comma-separated). Falls back to just the name if none set.
#' Each field gets its own row with alternating shading so adjacent
#' attributes (e.g. Bond vs Flaw) are easy to tell apart at a glance.
build_node_tooltip <- function(row) {
  visible <- character(0)
  if (!is.null(row$visible_fields) && !is.na(row$visible_fields) && row$visible_fields != "") {
    visible <- trimws(strsplit(row$visible_fields, ",")[[1]])
  }

  parts <- paste0("<div style='font-weight:bold;padding:3px 4px;'>", row$name, "</div>")
  shown <- 0
  for (f in visible) {
    if (!f %in% names(row)) next
    val <- row[[f]]
    if (length(val) == 0 || is.na(val)) next
    val_chr <- as.character(val)
    if (val_chr == "") next

    label <- tools::toTitleCase(gsub("_", " ", f))
    field_html <- format_tooltip_field(label, val_chr, max_chars = 140)
    field_html <- sub("<br>$", "", field_html)  # we're using divs, not <br>, for row breaks

    bg <- if (shown %% 2 == 0) "#f2f2f2" else "#ffffff"
    parts <- paste0(parts, "<div style='background-color:", bg, ";padding:3px 4px;'>", field_html, "</div>")
    shown <- shown + 1
  }
  parts
}

#' Build an interactive visNetwork widget from a tbl_graph.
make_visNetwork_graph <- function(g) {
  nodes_vis <- g |>
    activate(nodes) |>
    as_tibble() |>
    mutate(id = row_number())

  nodes_vis$title <- purrr::pmap_chr(nodes_vis, function(...) build_node_tooltip(list(...)))

  nodes_vis <- nodes_vis |>
    mutate(
      label = name,
      group = node_type,
      shape = ifelse(node_type == "house", "square", "dot"),
      size = 7
    )

  edges_vis <- g |>
    activate(edges) |>
    as_tibble() |>
    mutate(
      id = row_number(),
      title = paste0(
        "<b>", edge_labels[edge_type], "</b><br>",
        format_tooltip_field("Nature", relationship_nature, max_chars = 150),
        format_tooltip_field("Intentions", intentions),
        format_tooltip_field("Position", position),
        format_tooltip_field("Sentiment", sentiment),
        format_tooltip_field("Standing", standing),
        format_tooltip_field("Additional Desc", additional_desc, max_chars = 200)
      ),
      color = case_when(
        edge_type == "member_house" ~ "#c99a4b",
        edge_type == "NPC_NPC"      ~ "#4c9a6b",
        edge_type == "house_house"  ~ "#8a4c9a",
        TRUE ~ "gray"
      ),
      arrows = "to"
    )

  visNetwork(nodes_vis, edges_vis) |>
    visOptions(
      highlightNearest = list(enabled = TRUE, degree = 1, hover = TRUE),
      nodesIdSelection = TRUE,
      selectedBy = "group"
    ) |>
    visInteraction(
      tooltipStyle = paste(
        "position: fixed;",
        "visibility: hidden;",
        "padding: 0;",
        "white-space: normal;",
        "max-width: 260px;",
        "word-wrap: break-word;",
        "background-color: #fdfdfd;",
        "border: 1px solid #ccc;",
        "border-radius: 4px;",
        "box-shadow: 2px 2px 6px rgba(0,0,0,0.15);",
        "font-size: 12px;",
        "overflow: hidden;"
      )
    ) |>
    visEvents(select = "function(properties) {
      if (properties.edges.length > 0 && properties.nodes.length === 0) {
        Shiny.setInputValue('network_edge_selected', properties.edges[0], {priority: 'event'});
      }
    }") |>
    visLayout(randomSeed = 42) |>
    visEdges(smooth = TRUE) |>
    visPhysics(stabilization = TRUE)
}
