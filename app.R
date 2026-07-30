# app.R
# Interactive Shiny app for building/exploring a faction relationship graph.
# Loads a fictional placeholder world by default (see data/seed_data.R)
# so nobody's real campaign data has to be public for the demo to work.

library(shiny)
library(tidyverse)
library(tidygraph)
library(visNetwork)

source("R/graph_core.R")
source("R/node_functions.R")
source("R/edge_functions.R")
source("R/visualize.R")
source("R/trait_roller.R")
source("R/name_roller.R")
source("data/seed_data.R")

# Which edge_type(s) are valid for a given (from_type, to_type) pair.
# Both member_house and NPC_house are directional (NPC -> house).
valid_rel_types <- function(from_type, to_type) {
  if (is.null(from_type) || is.null(to_type)) return(character(0))
  if (from_type == "NPC" && to_type == "house") return(c("member_house", "NPC_house"))
  if (from_type == "NPC" && to_type == "NPC")   return("NPC_NPC")
  if (from_type == "house" && to_type == "house") return("house_house")
  character(0)
}

rel_type_labels <- c(
  member_house = "NPC is a member of this house",
  NPC_house    = "NPC has ties to this house (non-member)",
  NPC_NPC      = "Personal relationship",
  house_house  = "House-to-house relationship"
)

# Node schema fields worth exposing in the generic editor (skip node_type/name).
editable_node_fields <- function(node_type) {
  if (node_type == "house") names(house_schema) else names(npc_schema)
}

ui <- fluidPage(
  titlePanel("Faction Relationship Graph (demo)"),
  sidebarLayout(
    sidebarPanel(
      width = 4,
      tabsetPanel(
        tabPanel("Add House",
          br(),
          fluidRow(
            column(8, textInput("house_name", "House name")),
            column(4, actionButton("suggest_house_name", "Suggest", style = "margin-top:25px;"))
          ),
          uiOutput("house_name_suggestions_ui"),
          textInput("house_city", "City", value = "Aldenmere"),
          textAreaInput("house_desc", "Description", rows = 3),
          actionButton("add_house_btn", "Add House", class = "btn-primary")
        ),
        tabPanel("Add NPC",
          br(),
          radioButtons("npc_name_style", "Name style",
                       choices = c("Fantasy (procedural, offline)" = "procedural",
                                   "Realistic (external generator, by country)" = "realistic"),
                       selected = "procedural"),
          conditionalPanel(
            condition = "input.npc_name_style == 'realistic'",
            selectInput("npc_nationality", "Country / inspiration",
                        choices = realistic_name_nationalities)
          ),
          fluidRow(
            column(8, textInput("npc_name", "NPC name")),
            column(4, actionButton("suggest_npc_name", "Suggest", style = "margin-top:25px;"))
          ),
          uiOutput("npc_name_suggestions_ui"),
          numericInput("npc_age", "Age", value = NA, min = 0),
          textAreaInput("npc_desc", "Description", rows = 3),
          checkboxInput("npc_roll_traits", "Roll personality/bond/flaw/ideal", value = TRUE),
          actionButton("add_npc_btn", "Add NPC", class = "btn-primary")
        ),
        tabPanel("Add Relationship",
          br(),
          helpText("Tip: click a node on the graph, then use the buttons below to fill From/To."),
          uiOutput("rel_from_ui"),
          fluidRow(
            column(12, actionButton("pick_from_btn", "\u2193 Use clicked node as From",
                                     class = "btn-sm btn-outline-secondary"))
          ),
          br(),
          uiOutput("rel_to_ui"),
          fluidRow(
            column(12, actionButton("pick_to_btn", "\u2193 Use clicked node as To",
                                     class = "btn-sm btn-outline-secondary"))
          ),
          br(),
          uiOutput("rel_type_ui"),
          conditionalPanel(
            condition = "input.rel_type == 'member_house'",
            textInput("rel_position", "Position (e.g. Head of Household, Heir)")
          ),
          textInput("rel_nature", "Nature (e.g. rival, sibling, ally, creditor)"),
          textInput("rel_sentiment", "Sentiment / standing"),
          textInput("rel_intentions", "Intentions (optional)"),
          textAreaInput("rel_additional", "Additional details (optional)", rows = 2),
          checkboxInput("rel_mutual", "Mutual (adds the reverse tie too)", value = FALSE),
          actionButton("add_rel_btn", "Add Relationship", class = "btn-primary")
        ),
        tabPanel("Roll Traits",
          br(),
          helpText("Reroll personality trait, bond, flaw, and ideal for an existing NPC."),
          uiOutput("reroll_npc_ui"),
          actionButton("reroll_btn", "Roll New Traits", class = "btn-primary")
        ),
        tabPanel("Save / Load",
          br(),
          helpText("The graph only lives in memory while the app is running — download it to keep your work."),
          downloadButton("download_graph_btn", "Download current graph (.rds)"),
          hr(),
          fileInput("upload_graph_file", "Load a saved graph (.rds)", accept = ".rds"),
          actionButton("load_graph_btn", "Load (replaces current graph)", class = "btn-danger")
        ),
        tabPanel("Edit / Delete",
          br(),
          tabsetPanel(
            tabPanel("Node",
              br(),
              uiOutput("edit_node_ui"),
              uiOutput("edit_node_fields_ui"),
              fluidRow(
                column(6, actionButton("save_node_btn", "Save Changes", class = "btn-primary")),
                column(6, actionButton("delete_node_btn", "Delete Node", class = "btn-danger"))
              )
            ),
            tabPanel("Edge",
              br(),
              uiOutput("edit_edge_ui"),
              uiOutput("edit_edge_fields_ui"),
              fluidRow(
                column(6, actionButton("save_edge_btn", "Save Changes", class = "btn-primary")),
                column(6, actionButton("delete_edge_btn", "Delete Edge", class = "btn-danger"))
              )
            )
          )
        )
      )
    ),
    mainPanel(
      width = 8,
      visNetworkOutput("network", height = "500px"),
      hr(),
      fluidRow(
        column(6,
          h4("Inspect a node"),
          uiOutput("inspect_ui"),
          tableOutput("inspect_table")
        )
      )
    )
  )
)

server <- function(input, output, session) {
  graph_rv <- reactiveVal(build_seed_graph())

  all_nodes <- reactive({
    graph_rv() |> activate(nodes) |> as_tibble() |> mutate(id = row_number())
  })
  node_names <- reactive({ all_nodes() |> pull(name) |> sort() })
  npc_names  <- reactive({ all_nodes() |> filter(node_type == "NPC")   |> pull(name) |> sort() })
  house_names <- reactive({ all_nodes() |> filter(node_type == "house") |> pull(name) |> sort() })

  node_type_of <- function(name) {
    all_nodes() |> filter(name == !!name) |> pull(node_type) |> first()
  }

  output$network <- renderVisNetwork({ make_visNetwork_graph(graph_rv()) })

  # ------------------------------------------------------------------
  # Add House
  # ------------------------------------------------------------------
  house_suggestions <- reactiveVal(character(0))
  observeEvent(input$suggest_house_name, {
    house_suggestions(roll_name_options("house", n = 3))
  })
  output$house_name_suggestions_ui <- renderUI({
    req(length(house_suggestions()) > 0)
    div(
      style = "margin-bottom:10px;",
      lapply(house_suggestions(), function(nm) {
        actionButton(paste0("pick_house_", nm), nm, class = "btn-sm btn-outline-secondary",
                     style = "margin-right:4px;margin-bottom:4px;",
                     onclick = sprintf(
                       "Shiny.setInputValue('picked_house_name', '%s', {priority: 'event'})", nm
                     ))
      })
    )
  })
  observeEvent(input$picked_house_name, {
    updateTextInput(session, "house_name", value = input$picked_house_name)
  })

  observeEvent(input$add_house_btn, {
    req(input$house_name)
    tryCatch({
      graph_rv(add_house(graph_rv(), input$house_name,
                          city = input$house_city, desc = input$house_desc))
      updateTextInput(session, "house_name", value = "")
      updateTextAreaInput(session, "house_desc", value = "")
      house_suggestions(character(0))
    }, error = function(e) showNotification(conditionMessage(e), type = "error"))
  })

  # ------------------------------------------------------------------
  # Add NPC
  # ------------------------------------------------------------------
  npc_suggestions <- reactiveVal(character(0))
  observeEvent(input$suggest_npc_name, {
    if (identical(input$npc_name_style, "realistic")) {
      tryCatch({
        nm <- roll_name_realistic(input$npc_nationality)
        npc_suggestions(nm)
      }, error = function(e) showNotification(conditionMessage(e), type = "error"))
    } else {
      npc_suggestions(roll_name_options("given", n = 3))
    }
  })
  output$npc_name_suggestions_ui <- renderUI({
    req(length(npc_suggestions()) > 0)
    div(
      style = "margin-bottom:10px;",
      lapply(npc_suggestions(), function(nm) {
        actionButton(paste0("pick_npc_", nm), nm, class = "btn-sm btn-outline-secondary",
                     style = "margin-right:4px;margin-bottom:4px;",
                     onclick = sprintf(
                       "Shiny.setInputValue('picked_npc_name', '%s', {priority: 'event'})", nm
                     ))
      })
    )
  })
  observeEvent(input$picked_npc_name, {
    updateTextInput(session, "npc_name", value = input$picked_npc_name)
  })

  observeEvent(input$add_npc_btn, {
    req(input$npc_name)
    tryCatch({
      g <- add_NPC(graph_rv(), input$npc_name, age = input$npc_age, desc = input$npc_desc)
      if (isTRUE(input$npc_roll_traits)) {
        traits <- roll_all_traits()
        g <- do.call(update_node, c(list(graph = g, node_name = input$npc_name), traits))
      }
      graph_rv(g)
      updateTextInput(session, "npc_name", value = "")
      updateTextAreaInput(session, "npc_desc", value = "")
      npc_suggestions(character(0))
    }, error = function(e) showNotification(conditionMessage(e), type = "error"))
  })

  # ------------------------------------------------------------------
  # Add Relationship (from/to first, then valid types only)
  # ------------------------------------------------------------------
  output$rel_from_ui <- renderUI({
    selectInput("rel_from", "From", choices = node_names())
  })
  output$rel_to_ui <- renderUI({
    choices <- setdiff(node_names(), input$rel_from)
    selectInput("rel_to", "To", choices = choices)
  })

  # Node clicked on the graph -> its name, via visNetwork's built-in
  # input$network_selected (the row_number id we assigned as node id).
  clicked_node_name <- reactive({
    req(input$network_selected)
    if (input$network_selected == "") return(NULL)
    all_nodes() |> filter(id == as.integer(input$network_selected)) |> pull(name)
  })
  observeEvent(input$pick_from_btn, {
    nm <- clicked_node_name()
    if (is.null(nm) || length(nm) == 0) {
      showNotification("Click a node on the graph first.", type = "warning")
    } else {
      updateSelectInput(session, "rel_from", selected = nm)
    }
  })
  observeEvent(input$pick_to_btn, {
    nm <- clicked_node_name()
    if (is.null(nm) || length(nm) == 0) {
      showNotification("Click a node on the graph first.", type = "warning")
    } else {
      updateSelectInput(session, "rel_to", selected = nm)
    }
  })

  output$rel_type_ui <- renderUI({
    req(input$rel_from, input$rel_to)
    types <- valid_rel_types(node_type_of(input$rel_from), node_type_of(input$rel_to))
    if (length(types) == 0) {
      helpText("No relationship type exists in that direction — try swapping From/To.")
    } else {
      selectInput("rel_type", "Relationship type",
                  choices = setNames(types, rel_type_labels[types]))
    }
  })

  observeEvent(input$add_rel_btn, {
    req(input$rel_from, input$rel_to, input$rel_type)
    tryCatch({
      g <- graph_rv()
      g <- switch(input$rel_type,
        member_house = NPC_assign_house(g, input$rel_from, input$rel_to,
                                         position = input$rel_position,
                                         sentiment = input$rel_sentiment,
                                         intentions = input$rel_intentions,
                                         additional_desc = input$rel_additional),
        NPC_NPC = add_NPC_relationship(g, input$rel_from, input$rel_to,
                                        relationship_nature = input$rel_nature,
                                        sentiment = input$rel_sentiment,
                                        mutual = input$rel_mutual,
                                        intentions = input$rel_intentions,
                                        additional_desc = input$rel_additional),
        house_house = add_house_relations(g, input$rel_from, input$rel_to,
                                           standing = input$rel_sentiment,
                                           mutual = input$rel_mutual,
                                           intentions = input$rel_intentions,
                                           additional_desc = input$rel_additional),
        NPC_house = add_relationship(g, input$rel_from, input$rel_to,
                                      edge_type = "NPC_house",
                                      relationship_nature = input$rel_nature,
                                      standing = input$rel_sentiment,
                                      intentions = input$rel_intentions,
                                      additional_desc = input$rel_additional)
      )
      graph_rv(g)
      showNotification("Relationship added.", type = "message")
    }, error = function(e) showNotification(conditionMessage(e), type = "error"))
  })

  # ------------------------------------------------------------------
  # Reroll traits
  # ------------------------------------------------------------------
  output$reroll_npc_ui <- renderUI({
    selectInput("reroll_npc", "NPC", choices = npc_names())
  })
  observeEvent(input$reroll_btn, {
    req(input$reroll_npc)
    tryCatch({
      traits <- roll_all_traits()
      g <- do.call(update_node, c(list(graph = graph_rv(), node_name = input$reroll_npc), traits))
      graph_rv(g)
      showNotification(paste("Rolled new traits for", input$reroll_npc), type = "message")
    }, error = function(e) showNotification(conditionMessage(e), type = "error"))
  })

  # ------------------------------------------------------------------
  # Edit / Delete: Node
  # ------------------------------------------------------------------
  output$edit_node_ui <- renderUI({
    selectInput("edit_node_name", "Node", choices = node_names())
  })

  output$edit_node_fields_ui <- renderUI({
    req(input$edit_node_name)
    ntype <- node_type_of(input$edit_node_name)
    row <- all_nodes() |> filter(name == input$edit_node_name)
    fields <- setdiff(editable_node_fields(ntype), c("node_type", "visible_fields"))

    current_visible <- row$visible_fields
    current_visible <- if (length(current_visible) == 0 || is.na(current_visible) || current_visible == "") {
      character(0)
    } else {
      trimws(strsplit(current_visible, ",")[[1]])
    }

    field_inputs <- lapply(fields, function(f) {
      val <- row[[f]]
      val <- if (length(val) == 0 || is.na(val)) "" else as.character(val)
      if (f == "desc" || grepl("goals_n_interests|scandals|secrets|additional", f)) {
        textAreaInput(paste0("edit_field_", f), f, value = val, rows = 2)
      } else {
        textInput(paste0("edit_field_", f), f, value = val)
      }
    })

    tagList(
      field_inputs,
      hr(),
      checkboxGroupInput("edit_visible_fields",
                          "Show on graph tooltip (unchecked = kept in your notes only)",
                          choices = fields, selected = current_visible)
    )
  })

  observeEvent(input$save_node_btn, {
    req(input$edit_node_name)
    ntype <- node_type_of(input$edit_node_name)
    fields <- setdiff(editable_node_fields(ntype), c("node_type", "name", "visible_fields"))
    updates <- lapply(fields, function(f) input[[paste0("edit_field_", f)]])
    names(updates) <- fields
    updates <- updates[!sapply(updates, is.null)]
    # numeric fields need converting back
    for (num_field in intersect(names(updates), c("age", "CR"))) {
      suppressWarnings(updates[[num_field]] <- as.integer(updates[[num_field]]))
    }
    updates$visible_fields <- paste(input$edit_visible_fields, collapse = ",")
    tryCatch({
      g <- do.call(update_node, c(list(graph = graph_rv(), node_name = input$edit_node_name), updates))
      graph_rv(g)
      showNotification("Node updated.", type = "message")
    }, error = function(e) showNotification(conditionMessage(e), type = "error"))
  })

  observeEvent(input$delete_node_btn, {
    req(input$edit_node_name)
    showModal(modalDialog(
      title = "Delete node?",
      paste0("This will permanently delete '", input$edit_node_name,
             "' and every edge connected to it."),
      footer = tagList(
        modalButton("Cancel"),
        actionButton("confirm_delete_node", "Delete", class = "btn-danger")
      )
    ))
  })
  observeEvent(input$confirm_delete_node, {
    tryCatch({
      graph_rv(remove_node(graph_rv(), input$edit_node_name))
      removeModal()
      showNotification("Node deleted.", type = "message")
    }, error = function(e) showNotification(conditionMessage(e), type = "error"))
  })

  # ------------------------------------------------------------------
  # Edit / Delete: Edge
  # ------------------------------------------------------------------
  edge_table <- reactive({
    nodes <- all_nodes()
    graph_rv() |>
      activate(edges) |>
      as_tibble() |>
      mutate(
        from_name = nodes$name[from],
        to_name = nodes$name[to],
        label = paste0(from_name, " \u2192 ", to_name, " (", edge_type, ")")
      )
  })

  output$edit_edge_ui <- renderUI({
    et <- edge_table()
    req(nrow(et) > 0)
    selectInput("edit_edge_label", "Edge", choices = setNames(seq_len(nrow(et)), et$label))
  })

  output$edit_edge_fields_ui <- renderUI({
    req(input$edit_edge_label)
    row <- edge_table()[as.integer(input$edit_edge_label), ]
    val <- function(x) if (is.na(x)) "" else as.character(x)
    tagList(
      textInput("edit_edge_nature", "Nature", value = val(row$relationship_nature)),
      textInput("edit_edge_sentiment", "Sentiment", value = val(row$sentiment)),
      textInput("edit_edge_standing", "Standing", value = val(row$standing)),
      textInput("edit_edge_position", "Position", value = val(row$position)),
      textInput("edit_edge_intentions", "Intentions", value = val(row$intentions)),
      textAreaInput("edit_edge_additional", "Additional details",
                     value = val(row$additional_desc), rows = 2)
    )
  })

  observeEvent(input$save_edge_btn, {
    req(input$edit_edge_label)
    row <- edge_table()[as.integer(input$edit_edge_label), ]
    tryCatch({
      g <- update_edge(graph_rv(), row$from_name, row$to_name,
                        relationship_nature = input$edit_edge_nature,
                        sentiment = input$edit_edge_sentiment,
                        standing = input$edit_edge_standing,
                        position = input$edit_edge_position,
                        intentions = input$edit_edge_intentions,
                        additional_desc = input$edit_edge_additional)
      graph_rv(g)
      showNotification("Edge updated.", type = "message")
    }, error = function(e) showNotification(conditionMessage(e), type = "error"))
  })

  observeEvent(input$delete_edge_btn, {
    req(input$edit_edge_label)
    row <- edge_table()[as.integer(input$edit_edge_label), ]
    showModal(modalDialog(
      title = "Delete edge?",
      paste0("This will permanently delete the '", row$edge_type, "' edge from '",
             row$from_name, "' to '", row$to_name, "'."),
      footer = tagList(
        modalButton("Cancel"),
        actionButton("confirm_delete_edge", "Delete", class = "btn-danger")
      )
    ))
  })
  observeEvent(input$confirm_delete_edge, {
    row <- edge_table()[as.integer(input$edit_edge_label), ]
    tryCatch({
      graph_rv(remove_edge(graph_rv(), row$from_name, row$to_name))
      removeModal()
      showNotification("Edge deleted.", type = "message")
    }, error = function(e) showNotification(conditionMessage(e), type = "error"))
  })

  # ------------------------------------------------------------------
  # Save / Load
  # ------------------------------------------------------------------
  output$download_graph_btn <- downloadHandler(
    filename = function() paste0("faction-graph-", Sys.Date(), ".rds"),
    content = function(file) saveRDS(graph_rv(), file)
  )

  observeEvent(input$load_graph_btn, {
    req(input$upload_graph_file)
    tryCatch({
      loaded <- readRDS(input$upload_graph_file$datapath)
      if (!inherits(loaded, "tbl_graph")) {
        stop("That file doesn't look like a saved graph from this app.")
      }
      graph_rv(loaded)
      showNotification("Graph loaded.", type = "message")
    }, error = function(e) showNotification(conditionMessage(e), type = "error"))
  })

  # ------------------------------------------------------------------
  # Inspect
  # ------------------------------------------------------------------
  output$inspect_ui <- renderUI({
    selectInput("inspect_node_name", NULL, choices = node_names())
  })
  output$inspect_table <- renderTable({
    req(input$inspect_node_name)
    inspect_node(graph_rv(), input$inspect_node_name) |> select(Attribute, Preview)
  })
}

shinyApp(ui, server)
