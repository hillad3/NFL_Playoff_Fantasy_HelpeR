# clean up environment and run the garbage collector
remove(list = ls())
gc()

## clear cache as needed
# nflreadr::clear_cache()

library(tidyverse)
library(shiny)
library(data.table)
library(DT)

nfl_teams <- nflreadr::load_teams(current = TRUE) %>%
  as_tibble() %>%
  select(team_abbr, team_name, team_conf, team_division, team_logo_espn) %>%
  mutate(team_name_w_abbr = paste0(team_name, " (", team_abbr, ")"))

nfl_player_stats <- bind_rows(
  nflreadr::load_player_stats(seasons = 2023L, stat_type = "offense") %>%
    as_tibble() %>%
    filter(position %in% c("QB", "RB", "FB", "WR", "TE")) %>%
    mutate(
      position = if_else(position == "FB", "RB", position),
      fumbles_lost = sack_fumbles_lost + rushing_fumbles_lost + receiving_fumbles_lost,
      two_pt_conversions = passing_2pt_conversions + rushing_2pt_conversions + receiving_2pt_conversions,
    ) %>% 
    rename(team_abbr = recent_team),
  nflreadr::load_player_stats(seasons = 2023L, stat_type = "kicking") %>%
    as_tibble() %>%
    rename(team_abbr = team) %>% 
    mutate(position = "K")
) %>%
  left_join(
    nfl_teams %>% select(team_abbr, team_conf, team_division), by = c("team_abbr")
  ) %>% 
  mutate(
    week = as.integer(week),
    lookup_string = paste0(position,", ",team_abbr,": ",player_name," (",team_division,", ID: ",player_id,")")
  ) %>% 
  select(
    position,
    week,
    lookup_string,
    player_id,
    player_name,
    team_abbr,
    team_conf,
    team_division,
    everything()
  ) %>% 
  arrange(position, player_name, week)

offensive_player_stats <- nfl_player_stats %>% 
  filter(position %in% c("QB", "RB", "FB", "WR", "TE")) %>%
  select(
    position,
    week,
    player_id,
    player_name,
    team_abbr,
    team_conf,
    team_division,
    passing_yards,
    passing_tds,
    rushing_yards,
    rushing_tds,
    receiving_yards,
    receiving_tds,
    interceptions,
    sacks,
    fumbles_lost,
    two_pt_conversions,
  )

qb_player_stats <- nfl_player_stats %>% 
  filter(position %in% c("QB")) %>%
  select(
    position,
    week,
    player_id,
    player_name,
    team_abbr,
    team_conf,
    team_division,
    passing_yards,
    passing_tds,
    rushing_yards,
    rushing_tds,
    receiving_yards,
    receiving_tds,
    interceptions,
    sacks,
    fumbles_lost,
    two_pt_conversions,
  ) %>%
  arrange(desc(passing_yards))

qb_player_season_stats <- qb_player_stats %>% 
  group_by(position, player_id, player_name, team_abbr, team_conf, team_division) %>% 
  reframe(
    games_played = n(),
    total_passing_yards = sum(passing_yards),
    avg_passing_yards_per_game = mean(passing_yards, na.rm = TRUE) %>% round(0),
    total_passing_tds = sum(passing_tds),
    avg_passing_tds_per_game = mean(passing_tds, na.rm = TRUE) %>% round(2),
    total_rushing_yards = sum(rushing_yards),
    avg_rushing_yards_per_game = mean(rushing_yards, na.rm = TRUE) %>% round(0),
    total_rushing_tds = sum(rushing_tds),
    avg_rushing_tds_per_game = mean(rushing_tds, na.rm = TRUE) %>% round(2),
    total_receiving_yards = sum(receiving_yards),
    avg_receiving_yards_per_game = mean(receiving_yards, na.rm = TRUE) %>% round(0),
    total_receiving_tds = sum(receiving_tds),
    avg_receiving_tds_per_game = mean(receiving_tds, na.rm = TRUE) %>% round(2),
  ) %>% 
  arrange(desc(total_passing_yards))

rb_player_stats <- nfl_player_stats %>% 
  filter(position %in% c("RB")) %>%
  select(
    position,
    week,
    player_id,
    player_name,
    team_abbr,
    team_conf,
    team_division,
    rushing_yards,
    rushing_tds,
    receiving_yards,
    receiving_tds,
    fumbles_lost,
    two_pt_conversions,
  ) %>%
  arrange(desc(rushing_yards))

rb_player_season_stats <- rb_player_stats %>% 
  group_by(position, player_id, player_name, team_abbr, team_conf, team_division) %>% 
  reframe(
    games_played = n(),
    total_rushing_yards = sum(rushing_yards),
    avg_rushing_yards_per_game = mean(rushing_yards, na.rm = TRUE) %>% round(0),
    total_rushing_tds = sum(rushing_tds),
    avg_rushing_tds_per_game = mean(rushing_tds, na.rm = TRUE) %>% round(2),
    total_receiving_yards = sum(receiving_yards),
    avg_receiving_yards_per_game = mean(receiving_yards, na.rm = TRUE) %>% round(0),
    total_receiving_tds = sum(receiving_tds),
    avg_receiving_tds_per_game = mean(receiving_tds, na.rm = TRUE) %>% round(2),
  ) %>% 
  arrange(desc(total_rushing_yards))

wr_player_stats <- nfl_player_stats %>% 
  filter(position %in% c("WR")) %>%
  select(
    position,
    week,
    player_id,
    player_name,
    team_abbr,
    team_conf,
    team_division,
    receiving_yards,
    receiving_tds,
    rushing_yards,
    rushing_tds,
    fumbles_lost,
    two_pt_conversions,
  ) %>%
  arrange(desc(receiving_yards))

wr_player_season_stats <- wr_player_stats %>% 
  group_by(position, player_id, player_name, team_abbr, team_conf, team_division) %>% 
  reframe(
    games_played = n(),
    total_receiving_yards = sum(receiving_yards),
    avg_receiving_yards_per_game = mean(receiving_yards, na.rm = TRUE) %>% round(0),
    total_receiving_tds = sum(receiving_tds),
    avg_receiving_tds_per_game = mean(receiving_tds, na.rm = TRUE) %>% round(2),
    total_rushing_yards = sum(rushing_yards),
    avg_rushing_yards_per_game = mean(rushing_yards, na.rm = TRUE) %>% round(0),
    total_rushing_tds = sum(rushing_tds),
    avg_rushing_tds_per_game = mean(rushing_tds, na.rm = TRUE) %>% round(2),
  ) %>% 
  arrange(desc(total_receiving_yards))

te_player_stats <- nfl_player_stats %>% 
  filter(position %in% c("TE")) %>%
  select(
    position,
    week,
    player_id,
    player_name,
    team_abbr,
    team_conf,
    team_division,
    receiving_yards,
    receiving_tds,
    fumbles_lost,
    two_pt_conversions,
  ) %>%
  arrange(desc(receiving_yards))

te_player_season_stats <- te_player_stats %>% 
  group_by(position, player_id, player_name, team_abbr, team_conf, team_division) %>% 
  reframe(
    games_played = n(),
    total_receiving_yards = sum(receiving_yards),
    avg_receiving_yards_per_game = mean(receiving_yards, na.rm = TRUE) %>% round(0),
    total_receiving_tds = sum(receiving_tds),
    avg_receiving_tds_per_game = mean(receiving_tds, na.rm = TRUE) %>% round(2),
  ) %>% 
  arrange(desc(total_receiving_yards))

kicking_player_stats <- nfl_player_stats %>% 
  select(
    position,
    week,
    player_id,
    player_name,
    team_abbr,
    team_conf,
    team_division,
    fg_made,
    fg_missed,
    fg_long,
    pat_made,
    pat_missed
  ) %>%
  arrange(desc(fg_made))

kicking_player_season_stats <- kicking_player_stats %>% 
  group_by(position, player_id, player_name, team_abbr, team_conf, team_division) %>% 
  reframe(
    games_played = n(),
    total_fg_made = sum(fg_made),
    max_fg_made = max(fg_long),
    total_pat_made = sum(pat_made),
  ) %>% 
  arrange(desc(total_fg_made))

team_lookupstring_position <- bind_rows(
  nfl_player_stats %>% 
    distinct(team_abbr, lookup_string, position) %>% 
    arrange(lookup_string),
  nfl_teams %>% 
    mutate(position = "Defense",
           lookup_string = paste0(position,", ",team_abbr," (",team_division,")")) %>% 
    select(team_abbr, lookup_string, position)
) %>% as.data.table()
roster_choices <- team_lookupstring_position %>% distinct(lookup_string) %>% as.list()
def_teams_choices <- nfl_teams %>% distinct(team_abbr) %>% as.list()

ui <- fluidPage(
  titlePanel("Playoff Fantasy Football"),
  tabsetPanel(
    tabPanel(
      "Select Roster",
      sidebarLayout(
        sidebarPanel(
          selectizeInput(
            inputId = "roster_selections_made",
            label = "Select Player or Defensive Team",
            choices = c("",roster_choices),
            options = list(maxItems = 1)
          ),
          actionButton(
            inputId = "add_player",
            label = "Add to Roster",
            icon = icon("add"),
            style="color: white; background-color: #0086b3; border-color: #2e6da4"
          ),
          p("", style="margin-top:10px"),
          textOutput(outputId = "roster_slots_remaining_text"),
          p("", style="margin-top:10px"),
          textOutput(outputId = "teams_available_text"),
          p("", style="margin-top:10px"),
          textOutput(outputId = "positions_available_text"),
          h1("", style = 'margin:100px'),
          selectizeInput(
            inputId = "roster_selections_removed",
            label = "Remove Player or Defensive Team",
            choices = NULL,
            options = list(maxItems = 1),
          ),
          actionButton(
            inputId = "remove_player",
            label = "Remove",
            icon = icon("trash", lib = "glyphicon"),
            style="color: white; background-color: gray; border-color: black"
          ),
          p("", style="margin-top:10px"),
          textOutput(outputId = "teams_on_roster_text"),
          p("", style="margin-top:10px"),
          textOutput(outputId = "positions_on_roster_text"),
          p("", style='margin-bottom:100px'),
          fluidPage(
            h4("Participant Information", style='font-weight:bold'),
            textInput("team_owner", label = "Player Name (your real one)"),
            textInput("owner_email", label = "Email"),
            textInput("team_name", label = "Fantasy Team Name"),
            p("Note: Team name will be displayed in rankings"),
            actionButton(inputId = "email_commish", label = "Email Roster to the Commish"),
            p(""),
            style = 'background-color:#ffffc2; border-style:solid; border-color:black;'
          ),
          width = 3
        ),
        mainPanel(
          fluidRow(
            h3("Current Roster"),
            DTOutput(outputId = "players_on_roster_DT")
          ),
          fluidRow(
            h3("Possible Players Available", style="margin-top:100px"),
            DTOutput(outputId = "players_remaining_DT"),
          )
        )
      )
    ),
    tabPanel(
      "Explore 2023 Stats",
      sidebarLayout(
        sidebarPanel(
          # this is a single select way to provide positions for the DT table
          selectInput(
            inputId = "selected_position",
            label = "Inspect a Position:",
            choices = list("QB", "RB", "WR", "TE", "K"),
            selected = "QB"
          ),
          checkboxGroupInput(
            "selected_teams",
            "Inspect Team(s):",
            choiceNames = as.list(nfl_teams$team_name_w_abbr),
            choiceValues = as.list(nfl_teams$team_abbr),
            selected = as.list(nfl_teams$team_abbr)
          ),
          width = 2
        ),
        mainPanel(
          tabsetPanel(
            p(),
            tabPanel("Regular Season Totals", DTOutput("statistics_season")),
            tabPanel("Weekly Totals", DTOutput("statistics_weekly"))
          )
        )
      )
    )
  )
)

server <- function(input, output, session) {

  ## this section is for stats exploration
  stats_dropdown <- reactive({
    input$selected_position
  })

  output$statistics_weekly <- renderDT({
    if (stats_dropdown() == "K") {
      kicking_player_stats %>%
        filter(team_abbr %in% input$selected_teams)
    } else if (stats_dropdown() == "QB") {
      qb_player_stats %>%
        filter(team_abbr %in% input$selected_teams)
    } else if (stats_dropdown() == "RB") {
      rb_player_stats %>%
        filter(team_abbr %in% input$selected_teams)
    } else if (stats_dropdown() == "WR") {
      wr_player_stats %>%
        filter(team_abbr %in% input$selected_teams)
    } else if (stats_dropdown() == "TE") {
      te_player_stats %>%
        filter(team_abbr %in% input$selected_teams)
    } 
  })
  
  output$statistics_season <- renderDT({
    if (stats_dropdown() == "K") {
      kicking_player_season_stats %>%
        filter(team_abbr %in% input$selected_teams)
    } else if (stats_dropdown() == "QB") {
      qb_player_season_stats %>%
        filter(team_abbr %in% input$selected_teams)
    } else if (stats_dropdown() == "RB") {
      rb_player_season_stats %>%
        filter(team_abbr %in% input$selected_teams)
    } else if (stats_dropdown() == "WR") {
      wr_player_season_stats %>%
        filter(team_abbr %in% input$selected_teams)
    } else if (stats_dropdown() == "TE") {
      te_player_season_stats %>%
        filter(team_abbr %in% input$selected_teams)
    } 
  })
  
  
  ## this section is for Roster Selection
  # count the number of roster spots available and display text
  
  roster <- reactiveValues(players = c(NULL))
  
  observeEvent(input$add_player,{
    if(input$roster_selections_made == ""){
      
    } else{
      roster$players <- c(roster$players, input$roster_selections_made) %>% sort()
    }
  })
  
  observeEvent(input$remove_player,{
    roster$players <- roster$players[!(roster$players %in% input$roster_selections_removed)]
  })
  
  roster_slots_remaining <- reactive({
    14-length(roster$players)
  }) 
  output$roster_slots_remaining_text <- renderText({
      paste0("Roster slot(s) remaining: ", roster_slots_remaining(), " of 14")
  })

  
  # keep track of teams selected on the roster
  teams_on_roster <- reactive({
    team_lookupstring_position[lookup_string %in% roster$players, team_abbr] %>% 
      unique() %>% 
      sort()
  })
  output$teams_on_roster_text <- renderText({
    if(is_empty(teams_on_roster())){
      "Teams on roster: None"
    } else {
      paste0("Teams on roster: ", paste0(teams_on_roster(), collapse = ",  "))
    }
  })
  
  # keep track of unselected teams
  teams_available <- reactive({
    team_lookupstring_position[!(team_abbr %in% teams_on_roster()), team_abbr] %>% unique() %>% sort()
  }) 
  output$teams_available_text <- renderText({
    paste0("Teams remaining: ", paste0(teams_available() %>% unlist(), collapse = ",  "))
  })
  
  
  # keep track of positions on the roster
  positions_selected <- reactive({
    team_lookupstring_position[lookup_string %in% roster$players, position]
  })
  output$positions_on_roster_text <- renderText({
    if(is_empty(positions_selected())){
      "Positions Filled: None"
    } else {
      paste0("Positions Filled: ", paste0(positions_selected() %>% unlist(), collapse = ",  "))
    }
  })
  
  players_remaining <- reactive({

    players_remaining <- team_lookupstring_position %>%
      filter(!(team_abbr %in% teams_on_roster()))
    
    if(length(positions_selected()[positions_selected() == "Defense"])>=1L){
      players_remaining <- players_remaining %>%
        filter(position != "Defense")
    }   
    if(length(positions_selected()[positions_selected() == "K"])>=1L){
      players_remaining <- players_remaining %>%
        filter(position != "K")
    }
    if(length(positions_selected()[positions_selected() == "QB"])>=3L){
      players_remaining <- players_remaining %>%
        filter(position != "QB")
    }
    # for RB, TE and WR, need to consider the flex position when filtering
    if((length(positions_selected()[positions_selected() == "RB"])==3L & 
       (length(positions_selected()[positions_selected() == "TE"])==3L |
        length(positions_selected()[positions_selected() == "WR"])==4L) )|
       (length(positions_selected()[positions_selected() == "RB"])>=4L)){
      players_remaining <- players_remaining %>%
        filter(position != "RB")
    }
    if((length(positions_selected()[positions_selected() == "TE"])==2L & 
        (length(positions_selected()[positions_selected() == "RB"])==4L |
         length(positions_selected()[positions_selected() == "WR"])==4L) )|
       (length(positions_selected()[positions_selected() == "TE"])>=3L)){
      players_remaining <- players_remaining %>%
        filter(position != "TE")
    }
    if((length(positions_selected()[positions_selected() == "WR"])==3L & 
        (length(positions_selected()[positions_selected() == "TE"])==3L |
         length(positions_selected()[positions_selected() == "RB"])==4L) )|
       (length(positions_selected()[positions_selected() == "WR"])>=4L)){
      players_remaining <- players_remaining %>%
        filter(position != "WR")
    }
    
    players_remaining <- players_remaining %>%
      distinct(lookup_string)
    
  })
  
  output$players_on_roster_DT <- renderDT({
    if(is_empty(roster$players)){
      DT::datatable(data.table(lookup_string = "Roster is empty"), options = list(pageLength = 25))
    } else {
      DT::datatable(data.table(lookup_string = roster$players), options = list(pageLength = 25))
    }
  })
  
  output$players_remaining_DT <- renderDT({players_remaining()})
  
  observeEvent(
    input$add_player,{
    updateSelectizeInput(
      session,
      inputId = "roster_selections_made",
      choices = c("",players_remaining()),
      selected = ""
    )
      
    updateSelectizeInput(
      session,
      inputId = "roster_selections_removed",
      choices = roster$players
    )
  })
  
  observeEvent(
    input$remove_player,{
      updateSelectizeInput(
        session,
        inputId = "roster_selections_made",
        choices = c("",players_remaining()),
        selected = ""
      )
      
      updateSelectizeInput(
        session,
        inputId = "roster_selections_removed",
        choices = roster$players
      )
    })
  
}


shinyApp(ui, server)

