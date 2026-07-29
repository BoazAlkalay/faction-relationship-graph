# app.R
# Interactive Shiny app for building/exploring a noble-house relationship
# graph. Loads a fictional placeholder world by default (see data/seed_data.R)
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
source("data/seed_data.R")

ui <- fluidPage(
  titlePanel("Noble Houses of Aldenmere (demo)"),
  sidebarLayout(
    sidebarPanel(
      width = 4,
      tabsetPanel(
        tabPanel("Add House",
          br(),
          textInput("house_name", "House name"),
          textInput("house_city", "City", value = "Aldenmere"),
          textAreaInput("house_desc", "Description", rows = 3),
          actionButton("add_house_btn", "Add House", class = "btn-primary")
        ),
        tabPanel("Add NPC",
          br(),
          textInput("npc_name", "NPC name"),
          numericInput("npc_age", "Age", value = NA, min = 0),
          textAreaInput("npc_desc", "Description", rows = 3),
          checkboxInput("npc_roll_traits", "Roll personality/bond/flaw/ideal", value = TRUE),
          actionButton("add_npc_btn", "Add NPC", class = "btn-primary")
        ),
        tabPanel("Add Relationship",
          br(),
          uiOutput("rel_from_ui"),
          uiOutput("rel_to_ui"),
          selectInput("rel_type", "Relationship type", choices = c(
            "NPC is a member of a house" = "member_house",
            "NPC to NPC" = "NPC_NPC",
            "House to house" = "house_house",
            "NPC to non-member house" = "NPC_house"
          )),
          textInput("rel_nature", "Nature (e.g. rival, sibling, ally)"),
          textInput("rel_sentiment", "Sentiment / standing"),
          checkboxInput("rel_mutual", "Mutual (adds the reverse tie too)", value = FALSE),
          actionButton("add_rel_btn", "Add Relationship", class = "btn-primary")
        ),
        tabPanel("Roll Traits",
          br(),
          helpText("Reroll personality trait, bond, flaw, and ideal for an existing NPC."),
          uiOutput("reroll_npc_ui"),
          actionButton("reroll_btn", "Roll New Traits", class = "btn-primary")
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

  node_names <- reactive({
    graph_rv() |> activate(nodes) |> as_tibble() |> pull(name) |> sort()
  })
  npc_names <- reactive({
    graph_rv() |> activate(nodes) |> as_tibble() |>
      filter(node_type == "NPC") |> pull(name) |> sort()
  })
  house_names <- reactive({
    graph_rv() |> activate(nodes) |> as_tibble() |>
      filter(node_type == "house") |> pull(name) |> sort()
  })

  output$network <- renderVisNetwork({
    make_visNetwork_graph(graph_rv())
  })

  # --- Add House ---------------------------------------------------
  observeEvent(input$add_house_btn, {
    req(input$house_name)
    tryCatch({
      graph_rv(add_house(graph_rv(), input$house_name,
                          city = input$house_city, desc = input$house_desc))
      updateTextInput(session, "house_name", value = "")
      updateTextAreaInput(session, "house_desc", value = "")
    }, error = function(e) showNotification(conditionMessage(e), type = "error"))
  })

  # --- Add NPC -------------------------------------------------------
  observeEvent(input$add_npc_btn, {
    req(input$npc_name)
    tryCatch({
      g <- add_NPC(graph_rv(), input$npc_name,
                   age = input$npc_age, desc = input$npc_desc)
      if (isTRUE(input$npc_roll_traits)) {
        traits <- roll_all_traits()
        g <- do.call(update_node, c(list(graph = g, node_name = input$npc_name), traits))
      }
      graph_rv(g)
      updateTextInput(session, "npc_name", value = "")
      updateTextAreaInput(session, "npc_desc", value = "")
    }, error = function(e) showNotification(conditionMessage(e), type = "error"))
  })

  # --- Add Relationship ----------------------------------------------
  output$rel_from_ui <- renderUI({
    selectInput("rel_from", "From", choices = node_names())
  })
  output$rel_to_ui <- renderUI({
    selectInput("rel_to", "To", choices = node_names())
  })

  observeEvent(input$add_rel_btn, {
    req(input$rel_from, input$rel_to)
    tryCatch({
      g <- graph_rv()
      g <- switch(input$rel_type,
        member_house = NPC_assign_house(g, input$rel_from, input$rel_to,
                                         sentiment = input$rel_sentiment),
        NPC_NPC = add_NPC_relationship(g, input$rel_from, input$rel_to,
                                        relationship_nature = input$rel_nature,
                                        sentiment = input$rel_sentiment,
                                        mutual = input$rel_mutual),
        house_house = add_house_relations(g, input$rel_from, input$rel_to,
                                           standing = input$rel_sentiment,
                                           mutual = input$rel_mutual),
        NPC_house = add_relationship(g, input$rel_from, input$rel_to,
                                      edge_type = "NPC_house",
                                      relationship_nature = input$rel_nature,
                                      standing = input$rel_sentiment)
      )
      graph_rv(g)
    }, error = function(e) showNotification(conditionMessage(e), type = "error"))
  })

  # --- Reroll traits ---------------------------------------------------
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

  # --- Inspect ---------------------------------------------------------
  output$inspect_ui <- renderUI({
    selectInput("inspect_node_name", NULL, choices = node_names())
  })
  output$inspect_table <- renderTable({
    req(input$inspect_node_name)
    inspect_node(graph_rv(), input$inspect_node_name) |> select(Attribute, Preview)
  })
}

shinyApp(ui, server)
