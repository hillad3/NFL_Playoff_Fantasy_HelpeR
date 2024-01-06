# clean up environment and run the garbage collector
remove(list = ls())
gc()

library(tidyverse)
library(shiny)
library(data.table)
library(DT)
library(shinyjs)

season_year <- 2023L
season_type <- c("REG")


get_team_names <- function(){
  # create data.table for NFL teams
  dt <- data.table::as.data.table(nflreadr::load_teams(current = TRUE))
  dt[,team_name_w_abbr := paste0(team_name, ' (', team_abbr, ')')]
  dt <- dt[,.(team_abbr, team_name, team_name_w_abbr, team_conf, team_division, team_logo_espn)]
  return(dt)
}

get_offensive_player_stats <- function(season_year_int = season_year, season_type_char = season_type){
  # create data.table for players, which is a combination of the offensive scorers plus kickers
  dt <- data.table::as.data.table(nflreadr::load_player_stats(seasons = season_year_int, stat_type = 'offense'))
  dt <- dt[season_type %in% season_type_char]
  
  setnames(dt, old=c('recent_team'), new=c('team_abbr'))
  
  # Full Backs are considered running backs for the analysis
  dt <- dt[position %in% c('QB', 'RB', 'FB', 'WR', 'TE')]
  dt[,position := if_else(position == 'FB', 'RB', position)]
  
  # consolidate fumbles lost and 2pt conversions into one statistic
  dt[,fumbles_lost := sack_fumbles_lost + rushing_fumbles_lost + receiving_fumbles_lost]
  dt[,two_pt_conversions := passing_2pt_conversions + rushing_2pt_conversions + receiving_2pt_conversions]
  
  # order columns
  dt <- dt[
    , .(
      position,
      week,
      player_id,
      player_name,
      team_abbr,
      passing_yards,
      passing_tds,
      rushing_yards,
      rushing_tds,
      receiving_yards,
      receiving_tds,
      interceptions,
      sacks,
      fumbles_lost,
      two_pt_conversions
    )
  ]
  
  # change data types to double prior to melting
  vars <- c(
    'passing_yards',
    'passing_tds',
    'rushing_yards',
    'rushing_tds',
    'receiving_yards',
    'receiving_tds',
    'interceptions',
    'sacks',
    'fumbles_lost',
    'two_pt_conversions'
  )
  dt[,c(vars) := lapply(.SD, as.numeric), .SDcols=vars]
  
  # melt into long format
  dt <- melt(
    dt,
    id.vars = c('position',
                'week',
                'player_id',
                'player_name',
                'team_abbr'),
    measure.vars = c(
      'passing_yards',
      'passing_tds',
      'rushing_yards',
      'rushing_tds',
      'receiving_yards',
      'receiving_tds',
      'interceptions',
      'sacks',
      'fumbles_lost',
      'two_pt_conversions'
    ),
    variable.factor = FALSE,
    variable.name = 'stat_label',
    value.name = 'football_value'
  )
  
  # calculate fantasy football points
  dt[,fantasy_points := case_when(
    stat_label == 'passing_yards' & football_value >= 400 ~ as.integer(football_value/50) + 2L,
    stat_label == 'passing_yards' & football_value < 400 ~ as.integer(football_value/50),
    stat_label == 'rushing_yards' & football_value >= 200 ~ as.integer(football_value/10L) + 2L,
    stat_label == 'rushing_yards' & football_value < 200 ~ as.integer(football_value/10L),
    stat_label == 'receiving_yards' & football_value >= 200 ~ as.integer(football_value/10L) + 2L,
    stat_label == 'receiving_yards' & football_value < 200 ~ as.integer(football_value/10L),
    stat_label %in% c('passing_tds', 'rushing_tds','receiving_tds') ~ as.integer(football_value) * 6L,
    stat_label %in% c('passing_2pt_conversions', 'rushing_2pt_conversions','receiving_2pt_conversions') ~ as.integer(football_value) * 2L,
    stat_label == 'interceptions' ~ as.integer(football_value) * -2L,
    stat_label %in% c('sack_fumbles_lost', 'rushing_fumbles_lost', 'receiving_fumbles_lost') ~ as.integer(football_value) * -2L,
    .default = 0L
  )
  ]
  
}

get_kicker_player_stats <- function(season_year_int = season_year, season_type_char = season_type){
  
  dt <- data.table::as.data.table(nflreadr::load_player_stats(seasons = season_year_int, stat_type = 'kicking'))
  dt <- dt[season_type %in% season_type_char]
  
  setnames(dt, old=c('team'), new=c('team_abbr'))
  
  # position is not in the original dataset
  dt[,position := 'K']
  
  # consolidate variables for fantasy scoring
  dt[,fg_made_50_ := fg_made_50_59 + fg_made_60_]
  
  # order columns
  dt <- dt[
    , .(
      position,
      week,
      player_id,
      player_name,
      team_abbr,
      fg_made,
      fg_made_40_49,
      fg_made_50_,
      fg_missed,
      fg_missed_list,
      fg_blocked,
      fg_blocked_list,
      pat_made,
      pat_missed
    )
  ]
  
  # change data types to double prior to melting
  vars <- c(
    'fg_made',
    'fg_made_40_49',
    'fg_made_50_',
    'fg_missed',
    'fg_blocked',
    'pat_made',
    'pat_missed'
  )
  dt[,c(vars) := lapply(.SD, as.numeric), .SDcols=vars]
  
  # melt data into long format
  dt <- melt(
    dt,
    id.vars = c('position',
                'week',
                'player_id',
                'player_name',
                'team_abbr'),
    measure.vars = c(
      'fg_made',
      'fg_made_40_49',
      'fg_made_50_',
      'fg_missed',
      'fg_blocked',
      'pat_made',
      'pat_missed'
    ),
    variable.factor = FALSE,
    variable.name = 'stat_label',
    value.name = 'football_value'
  )
  
  # calculate fantasy points
  dt[, fantasy_points := case_when(
    stat_label == 'fg_made' ~ as.integer(football_value) * 3L,
    stat_label == 'fg_made_40_49' ~ as.integer(football_value) * 1L, # this is a bonus
    stat_label == 'fg_made_50_' ~ as.integer(football_value) * 2L, # this is a bonus
    stat_label == 'fg_missed' ~ as.integer(football_value) * -1L,
    stat_label == 'pat_made' ~ as.integer(football_value) * 1L,
    stat_label == 'pat_missed' ~ as.integer(football_value) * -1L,
    .default = 0L
  )]
  
}

get_player_stats <- function(teams = dt_nfl_teams){
  
  # bind rows
  dt <- rbindlist(list(get_offensive_player_stats(), get_kicker_player_stats()))
  
  # join in team conf and division
  dt <- merge(dt, teams[,.(team_abbr, team_conf, team_division)], all.x = TRUE)
  
  # create the lookup_string used in the dashboard filters
  dt[,lookup_string := paste0(position,', ',team_abbr,': ',player_name,' (',team_division,', ID: ',player_id,')')]
  
  # sort columns
  setorder(dt, cols = position, player_name, week)
  
  # arrange columns
  setcolorder(
    dt,
    c(
      'position',
      'week',
      'lookup_string',
      'player_id',
      'player_name',
      'team_abbr',
      'team_conf',
      'team_division'
    )
  )
}

get_position_stats <- function(dt, pos, summarized_boolean, long_format_boolean){
  
  if(!(pos %in% c("K","QB","RB","TE","WR"))){
    print(paste0(pos, " is not a valid position"))
  }
  
  dt <- dt[position == pos]
  
  if(summarized_boolean){
    
    grouping_by <- c(
      'position',
      'lookup_string',
      'player_id',
      'player_name',
      'team_abbr',
      'team_conf',
      'team_division',
      'stat_label'
    )
    
    dt <- dt[, week:=NULL]
    
    dt <- dt[, by = grouping_by, 
             .(football_value = sum(football_value), fantasy_points = sum(fantasy_points))
    ]
    
    dt[, stat_label := paste0("total_",stat_label)]
  }
  
  if(long_format_boolean){
    # do nothing
  } else {
    
    # cast wider
    if(summarized_boolean){
      # does not include the `week` variable when summarized
      dt <- dcast(
        dt,
        position + lookup_string + player_id + player_name + team_abbr + team_conf + team_division ~ stat_label,
        value.var = c('football_value', 'fantasy_points'),
        fill = 0
      )   
    } else {
      dt <- dcast(
        dt,
        position + week + lookup_string + player_id + player_name + team_abbr + team_conf + team_division ~ stat_label,
        value.var = c('football_value', 'fantasy_points'),
        fill = 0
      )
    }
  }
  
  # order based on top priority columns
  if(pos=="K" & "football_value_total_fg_made" %in% names(dt)){
    setorder(dt, cols = football_value_total_fg_made)
  } else if(pos=="K" & "fantasy_points_total_fg_made" %in% names(dt)){
    setorder(dt, cols = fantasy_points_total_fg_made)
  } else if(pos=="QB" & "football_value_total_total_passing_yards" %in% names(dt)){
    setorder(dt, cols = fantasy_points_total_fg_made)
  } else if(pos=="QB" & "fantasy_points_total_total_passing_yards" %in% names(dt)){
    setorder(dt, cols = fantasy_points_total_fg_made)
  }
  
  return(dt)
  
}

order_cols <- function(dt){
  
  master_order <- c(
    'position',
    'lookup_string',
    'week',
    'player_id',
    'player_name',
    'team_abbr',
    'team_conf',
    'team_division',
    'passing_yards',
    'passing_tds',
    'rushing_yards',
    'rushing_tds',
    'receiving_yards',
    'receiving_tds',
    'interceptions',
    'sacks',
    'fumbles_lost',
    'two_pt_conversions',
    'fg_made',
    'fg_made_40_49',
    'fg_made_50_',
    'fg_missed',
    'fg_missed_list',
    'fg_blocked',
    'fg_blocked_list',
    'pat_made',
    'pat_missed',
    'stat_label',
    'football_value',
    'fantasy_points',
    'football_value_total_passing_tds',
    'fantasy_points_total_passing_tds',
    'football_value_total_receiving_tds',
    'fantasy_points_total_receiving_tds',
    'football_value_total_rushing_tds',
    'fantasy_points_total_rushing_tds',
    'football_value_total_passing_yards',
    'fantasy_points_total_passing_yards',
    'football_value_total_receiving_yards',
    'fantasy_points_total_receiving_yards',
    'football_value_total_rushing_yards',
    'fantasy_points_total_rushing_yards',
    'football_value_total_fumbles_lost',
    'fantasy_points_total_fumbles_lost',
    'football_value_total_interceptions',
    'fantasy_points_total_interceptions',
    'football_value_total_sacks',
    'fantasy_points_total_sacks',
    'football_value_total_two_pt_conversions',
    'fantasy_points_total_two_pt_conversions',
    'football_value_total_fg_made',
    'fantasy_points_total_fg_made',
    'football_value_total_fg_made_40_49',
    'fantasy_points_total_fg_made_40_49',
    'football_value_total_fg_made_50_',
    'fantasy_points_total_fg_made_50_',
    'football_value_total_fg_missed',
    'fantasy_points_total_fg_missed',
    'football_value_total_fg_blocked',
    'fantasy_points_total_fg_blocked',
    'football_value_total_pat_made',
    'fantasy_points_total_pat_made',
    'football_value_total_pat_missed',
    'fantasy_points_total_pat_missed',
    'football_value_passing_tds',
    'fantasy_points_passing_tds',
    'football_value_receiving_tds',
    'fantasy_points_receiving_tds',
    'football_value_rushing_tds',
    'fantasy_points_rushing_tds',
    'football_value_passing_yards',
    'fantasy_points_passing_yards',
    'football_value_rushing_yards',
    'fantasy_points_rushing_yards',
    'football_value_receiving_yards',
    'fantasy_points_receiving_yards',
    'football_value_fumbles_lost',
    'fantasy_points_fumbles_lost',
    'football_value_interceptions',
    'fantasy_points_interceptions',
    'football_value_sacks',
    'fantasy_points_sacks', 
    'football_value_two_pt_conversions',
    'fantasy_points_two_pt_conversions',
    'football_value_fg_made',
    'fantasy_points_fg_made',
    'football_value_fg_made_40_49',
    'fantasy_points_fg_made_40_49',
    'football_value_fg_made_50_',
    'fantasy_points_fg_made_50_',
    'football_value_fg_missed',
    'fantasy_points_fg_missed',
    'football_value_fg_blocked',
    'fantasy_points_fg_blocked',
    'football_value_pat_made',
    'fantasy_points_pat_made', 
    'football_value_pat_missed',
    'fantasy_points_pat_missed'
  )
  
  found_order <- names(dt)
  
  unmapped_cols <- found_order[!(found_order %in% master_order)]
  
  if(length(unmapped_cols)){
    print("There are unmapped columns in the dataset")
    print(paste0(unmapped_cols, collapse = "; "))
  }
  
  preferred_order <- master_order[master_order %in% found_order]
  
  return(dt[,..preferred_order])
  
}

count_positions <- function(x){
  position_counts <- c(NULL)
  position_tmp <- c(NULL)
  for(a in x){
    if(a %in% c("K","Defense")){
      position_counts <- c(position_counts,a)
    } else if((a == "RB" & sum(position_tmp==a)==3L) |
              (a == "TE" & sum(position_tmp==a)==2L) |
              (a == "WR" & sum(position_tmp==a)==3L)
    ){
      position_tmp <- c(position_tmp,a)
      position_counts <- c(position_counts,paste0("FLEX (",a,")"))
    } else {
      position_counts <- c(position_counts,paste0(a,sum(position_tmp==a)+1L))
      position_tmp <- c(position_tmp,a)
    }
  }
  return(position_counts)
}


# create data.table for NFL teams
dt_nfl_teams <- get_team_names()

# TODO currently I do not have functionality set up for team points calculated on pbp data
# create data.table for play-by-play data for scoring defensive points for each team
# dt_nfl_team_stats <- data.table::as.data.table(nflfastR::load_pbp(seasons = season_year))
# dt_nfl_team_stats[season_type %in% season_type]

# create data.table for players, which is a combination of the offensive scorers plus kickers
dt_nfl_player_stats <- get_player_stats()

# remove zero value statistics
dt_nfl_player_stats <- dt_nfl_player_stats[abs(fantasy_points) >= 1e-7 | abs(football_value) >= 1e-7]

# get a list of unique players for the lookup
dt_lookup <- unique(get_player_stats()[,.(position, lookup_string, team_abbr)], by=c('lookup_string'))
dt_lookup <- setorder(dt_lookup, cols = position, team_abbr, lookup_string)


dt_nfl_teams[,position:="Defense"]
dt_nfl_teams[,lookup_string:=paste0(position,", ",team_abbr," (",team_division,")")]

team_lookupstring_position <- rbindlist(list(dt_lookup, dt_nfl_teams[,.(position, lookup_string, team_abbr)]))

roster_choices <- team_lookupstring_position %>% distinct(lookup_string) %>% as.list()
def_teams_choices <- dt_nfl_teams %>% distinct(team_abbr) %>% as.list()


ui <- fluidPage(
  shinyjs::useShinyjs(),
  titlePanel("Playoff Fantasy Football"),
  tabsetPanel(
    tabPanel(
      "How to Play",
      fluidPage(
        h2("Game Overview"),
        p("Playoff Fantasy Football is an elimination based version of Fantasy Football:"),
        tags$ul(
          tags$li("Each contestant will create a diversified roster prior to the start of playoffs."),
          tags$ul(
            tags$li("Your roster must include one player from each of the 14 teams in the playoffs."),
            tags$li("Your roster must include:"),
              tags$ul(
                tags$li("1 Kicker (K)"),
                tags$li("3 Quaterbacks (QB)"),
                tags$li("3 Running Backs (RB)"),
                tags$li("3 Wide Receivers (WR)"),
                tags$li("2 Tight Ends (TE)"),
                tags$li("1 Flex Position (either RB, WR or TE)"),
                tags$li("1 Defense / Special Teams.")
              ),
          ),
          tags$li("The roster will be locked from changes after submission to the Commissioner. Each week, as teams are eliminated from the playoffs, so does the pool of potential players on your roster who can score points."),
          tags$ul(
            tags$li("Therefore, your overall roster success is as dependent on each player's longevity in the playoffs as much as it is on the player's performance.")
          ),
          tags$li("Fantasy scoring is calculated based on each player's performance during a game."),
          tags$li("The types of statistics converted into Fantasy scores is consistent with typical scoring rules (see details below)"),
          tags$li("All playoff games, including wildcards and the Super Bowl, will be considered in the scoring."),
          tags$li("Rosters must be submitted, valid, and paid for by kickoff of the first wildcard game (1pm Saturday, January 13th, 2023)."),
          tags$li("Multiple rosters are allowed per Owner, as long as each are paid for."),
          tags$li("Prizes will be awarded to the top 5 scoring entries."),
          tags$li("Prize purse will be announced after wildcard playoff weekend, since prize purse is dependent on the number of entries."),
          tags$li("If you think you're going to win, spread the word: The more participants, the larger the prizes."),
          tags$li("If you think you're going to lose, spread the word: Imagine the commaraderie of shared experience!"),
          tags$li("The Commissioner will (probably) provide weekly updates on Fantasy Team standings throughout the contest. Final summary of scoring and standings will be provided.")
        ),
        h2("How To Use this Dashboard"),
        p("You can use this dashboard to explore player statistics and create your roster:"),
        tags$ul(
          tags$li("Regular season statistics are available on the 'Explore 2023 Stats' tab, which may help provide insights on each player you should prioritize. Statistics are available in 'football values' and in 'fantasy points'. Defense / Special Team points are not available here -- but you know, like, google it."),
          tags$li("Use the 'Select Roster' tab on this dashboard to start creating your roster."),
          tags$li("Add players to your roster based on the combination you think will score the most points by the end of the Superbowl."),
          tags$li("When a player is added to your roster, the team associated with that player (and any of its remaining players) will be removed from your next possible selections. For example: if you pick Jalen Hurts as one of your quarterbacks, you no longer be able to select an Eagles player on your roster."),
          tags$li("When you've satisified the maximum number of positions on your roster, any player associated with that poisiton will be removed from your next possible selection. For example: if you pick Jalen Hurts as your third (and last) quarterback, you no longer be able to select a quarterback."),
          tags$li("As needed, you can remove players from your team, which will release that Team and/or Position as a next possible selection."),
          tags$li("You must include your Name, Email and Fantasy Team Name in the Participant Information Box. Don't forget to confirm that you've paid the Commish."),
          tags$li("The roster can only be downloaded after all parameters have been satisfied (that is, a completed roster of 14 players and the Participant Information box is filled in with valid information)."),
          tags$li("You must still email the commissioner your roster downloaded from this website. This website does not save your roster.", style="color:red; font-weight:bold;"),
        ),
        h2("Alternate Roster in Excel"),
        p("The email sent to you by the Commissioner should contain an Excel file that is equivalent to this dashboard. If you prefer, you can complete that roster template and email the Excel file back to the Commissioner. I don't know why you would do this, but technically it is possible."),
        h2("Scoring"),
        h4("Passing"),
        tags$ul(
          tags$li("TD Pass = 6 points"),
          tags$li("Every 50 passing yards = 1 point"),
          tags$li("400+ Yards in a single game = 2 points"),
          tags$li("40+ Yard Passing TD = 2 points"),
          tags$li("2pt Passing Conversion = 2 points"),
          tags$li("Interception Thrown = -2 points"),
          tags$li("Fumble Lost = -2 points"),
        ),
        h4("Rushing"),
        tags$ul(
          tags$li("TD Rush = 6 points"),
          tags$li("Every 10 rushing yards = 1 point"),
          tags$li("200+ Yards in a single game = 2 points"),
          tags$li("40+ Yard Passing TD = 2 points"),
          tags$li("2pt rushing Conversion = 2 points"),
          tags$li("Fumble Lost = -2 points"),
        ),
        h4("Receiving"),
        tags$ul(
          tags$li("TD Receiving = 6 points"),
          tags$li("Every 10 receiving yards = 1 point"),
          tags$li("200+ Yards in a single game = 2 points"),
          tags$li("40+ Yard Receiving TD = 2 points"),
          tags$li("2pt rushing Conversion = 2 points"),
          tags$li("Fumble Lost = -2 points"),
        ),
        h4("Kicking"),
        tags$ul(
          tags$li("PAT Made = 1 point"),
          tags$li("PAT Missed = -1 point"),
          tags$li("FG Made = 3 points"),
          tags$li("FG Made (40-49 yards) Bonus = 1 point"),
          tags$li("FG Made (50+ yards) Bonus = 2 points"),
          tags$li("FG Missed = -1 point"),
        ),
        h4("Defense / Special Teams"),
        tags$ul(
          tags$li("Each Sack = 1 point"),
          tags$li("Each Interception = 2 points"),
          tags$li("Each Safety = 2 points"),
          tags$li("Each Fumble Recovery = 2 points"),
          tags$li("Each Blocked Punt, PAT or FG = 2 points"),
          tags$li("Interception Return TD = 6 points"),
          tags$li("Fumble Return TD = 6 points"),
          tags$li("Kickoff Return TD = 6 points"),
          tags$li("Punt Return TD = 6 points"),
          tags$li("Blocked Punt or FG Return TD = 6 points"),
          tags$li("0 Points Allowed = 10 points"),
          tags$li("1-6 Points Allowed = 7 points"),
          tags$li("7-13 Points Allowed = 4 points"),
          tags$li("14-21 Points Allowed = 1 points"),
          tags$li("22-27 Points Allowed = -1 points"),
          tags$li("28-34 Points Allowed = -4 points"),
          tags$li("35-45 Points Allowed = -7 points"),
          tags$li("46+ Points Allowed = -10 points"),
        )
      )
    ),
    tabPanel(
      "Select Roster",
      actionButton(
        inputId = "toggleRosterSelector", 
        label = "Toggle Roster Selector",
        icon = icon("bars"),
        style = "margin-top:3px; margin-bottom:3px"
      ),
      sidebarLayout(
        div(id = "rosterSelector",
          sidebarPanel(
            selectizeInput(
              inputId = "roster_selections_made",
              label = "Select Player or Defensive Team",
              choices = roster_choices,
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
            textOutput(outputId = "positions_available_text"),
            p("", style="margin-top:10px"),
            textOutput(outputId = "teams_available_text"),
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
            textOutput(outputId = "positions_on_roster_text"),
            p("", style="margin-top:10px"),
            textOutput(outputId = "teams_on_roster_text"),
            p("", style='margin-bottom:25px'),
            fluidPage(
              h4("Participant Information", style='font-weight:bold; margin-bottom:0px'),
              p("* required", style = "color:red; margin-top:3px"),
              textInput("fantasy_owner_name", label = "Name *", placeholder = "Dick Butkus"),
              textInput("fantasy_owner_email", label = "Email * ", placeholder = "myemail@gmail.com"),
              textInput("fantasy_team_name", label = "Fantasy Team Name * ", placeholder = "Unique Team Name (especially if submitting multiple rosters)"),
              checkboxInput("paid_checkbox", label = "I have paid the Commish because I am not a delinquent *"),
              p("Note: Fantasy Team Name will be displayed in rankings", style='margin-top:20px'),
              style = 'background-color:#ffffc2; border-style:solid; border-color:black;'
            ),
            p("", style='margin-bottom:20px'),
            downloadButton(
              outputId = "download_roster", 
              label = "Download Roster",
              style = "color: white; background-color: #F62817;"
            ),
            p("Don't forget to email your roster to the Commish!"),
            width = 4
          )
        ),
        mainPanel(
          fluidRow(
            h3("Current Roster"),
            DTOutput(outputId = "players_on_roster_DT"),
            style="margin-left:2px"
          ),
          fluidRow(
            h3("Valid Player Selections Remaining", style="margin-top:100px"),
            DTOutput(outputId = "players_remaining_DT"),
            style="margin-left:2px"
          )
        )
      )
    ),
    tabPanel(
      "Explore 2023 Stats",
      actionButton(
        inputId = "toggleFilterOptions", 
        label = "Toggle Filter Options",
        icon = icon("bars"),
        style = "margin-top:3px; margin-bottom:3px"
      ),
      sidebarLayout(
        div(id = "filterOptions",
          sidebarPanel(
            # this is a single select way to provide positions for the DT table
            selectInput(
              inputId = "selected_position",
              label = "Inspect a Position:",
              choices = list("QB", "RB", "WR", "TE", "K"),
              selected = "QB"
            ),
            selectInput(
              inputId = "stat_type",
              label = "Statistic Type:",
              choices = list("Football Values", "Fantasy Points", "Both"),
              selected = "Football Value"
            ),
            p("Inspect Team(s)", style = "font-weight:bold; margin-top:40px"),
            actionButton("select_all_teams", label="All", inline=TRUE),
            actionButton("deselect_all_teams", label="None", inline=TRUE),
            checkboxGroupInput(
              "selected_teams",
              label = "",
              choiceNames = as.list(dt_nfl_teams$team_name_w_abbr),
              choiceValues = as.list(dt_nfl_teams$team_abbr),
              selected = as.list(dt_nfl_teams$team_abbr)
            ),
            width = 2
          )
        ),
        mainPanel(
          tabsetPanel(
            p("", style="margin-top:10px"),
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
  observeEvent(input$toggleFilterOptions, {
    shinyjs::toggle(id = "filterOptions")
  })
  
  
  stats_dropdown <- reactive({
    input$selected_position
  })

  output$statistics_weekly <- renderDT({
    player_stats <- get_position_stats(
      dt_nfl_player_stats, 
      stats_dropdown(), 
      summarized_boolean = FALSE, 
      long_format_boolean = FALSE
    ) 
    
    player_stats <- order_cols(player_stats[team_abbr %in% input$selected_teams])
    if(input$stat_type == "Football Values"){
      cols <- c('position','lookup_string', 'week', 'player_id', 'player_name',
                'team_abbr', 'team_conf', 'team_division',
                names(player_stats)[str_detect(names(player_stats),"^football_value")])
      return(player_stats[, .SD, .SDcols = cols])
    } else if (input$stat_type == "Fantasy Points"){
      cols <- c('position','lookup_string', 'week', 'player_id', 'player_name',
                'team_abbr', 'team_conf', 'team_division',
                names(player_stats)[str_detect(names(player_stats),"^fantasy_points")])
      return(player_stats[, .SD, .SDcols = cols])
    } else {
      return(player_stats)
    }
  })
  
  output$statistics_season <- renderDT({
    player_stats <- get_position_stats(
      dt_nfl_player_stats, 
      stats_dropdown(), 
      summarized_boolean = TRUE, 
      long_format_boolean = FALSE
    ) %>% order_cols()
    
    player_stats <- order_cols(player_stats[team_abbr %in% input$selected_teams])
    if(input$stat_type == "Football Values"){
      cols <- c('position','lookup_string', 'player_id', 'player_name', 
                'team_abbr', 'team_conf', 'team_division',
                names(player_stats)[str_detect(names(player_stats),"^football_value")])
      return(player_stats[, .SD, .SDcols = cols])
    } else if (input$stat_type == "Fantasy Points"){
      cols <- c('position','lookup_string', 'player_id', 'player_name', 
                'team_abbr', 'team_conf', 'team_division',
                names(player_stats)[str_detect(names(player_stats),"^fantasy_points")])
      return(player_stats[, .SD, .SDcols = cols])
    } else {
      return(player_stats)
    }
  })
  
  observeEvent(
    input$select_all_teams, {
    updateCheckboxGroupInput(
      session,
      "selected_teams",
      label = "",
      choiceNames = as.list(dt_nfl_teams$team_name_w_abbr),
      choiceValues = as.list(dt_nfl_teams$team_abbr),
      selected = as.list(dt_nfl_teams$team_abbr)
    )
  })
  
  observeEvent(
    input$deselect_all_teams, {
    updateCheckboxGroupInput(
      session,
      "selected_teams",
      label = "",
      choiceNames = as.list(dt_nfl_teams$team_name_w_abbr),
      choiceValues = as.list(dt_nfl_teams$team_abbr),
      selected = NULL
    )
  })
  
  
  ## this section is for Roster Selection
  
  observeEvent(input$toggleRosterSelector, {
    shinyjs::toggle(id = "rosterSelector")
  })
  
  roster <- reactiveValues(players = c(NULL))
  
  observeEvent(input$add_player,{
      roster$players <- c(roster$players, input$roster_selections_made) %>% sort()
  })
  
  observeEvent(input$remove_player,{
    roster$players <- roster$players[!(roster$players %in% input$roster_selections_removed)]
  })
  
  roster_slots_remaining <- reactive({
    14-length(roster$players)
  }) 
  
  roster_full <- reactive({
    if(length(roster$players) == 14L){
      TRUE
    } else {
      FALSE
    }
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
      paste0("Positions Filled: ", paste0(count_positions(positions_selected()) %>% unlist(), collapse = ",  "))
    }
  })
  
  output$positions_available_text <- renderText({
    if(length(positions_selected())==14L){
      "Positions Remaining: None"
    } else {
      all_positions <- c("K","QB1","QB2","QB3","RB1","RB2","RB3","TE1","TE2","WR1","WR2","WR3","FLEX","Defense")
      current_positions <- count_positions(positions_selected())
      current_positions <- str_remove(current_positions," .[:alpha:]{2}.")
      remaining_positions <- all_positions[!(all_positions %in% current_positions)]
      paste0("Positions Remaining: ", paste0(remaining_positions %>% unlist(), collapse = ",  "))
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
    
    players_remaining <- players_remaining %>% select(position, team_abbr, lookup_string)
    
  })
  
  output$players_on_roster_DT <- renderDT({
    if(is_empty(roster$players)){
      DT::datatable(
        data.table(lookup_string = "Roster is empty"), 
        options = list(pageLength = 25)
      )
    } else {
      DT::datatable(
        team_lookupstring_position[lookup_string %in% roster$players, 
                                   .(position, team_abbr, lookup_string)],
        options = list(pageLength = 25)
      )
    }
  })
  
  output$players_remaining_DT <- renderDT({players_remaining()})
  
  observeEvent(
    input$add_player,{
    updateSelectizeInput(
      session,
      inputId = "roster_selections_made",
      choices = players_remaining()$lookup_string
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
        choices = players_remaining()$lookup_string
      )
      
      updateSelectizeInput(
        session,
        inputId = "roster_selections_removed",
        choices = roster$players
      )
    })
  
  observeEvent(
    roster_full(),
    {
      if(roster_full()) {
        shinyjs::disable("add_player")
        
      } else {
        shinyjs::enable("add_player")
      }
    }
  )
  


  # reactive boolean for activating download button
  participant_info <- reactive({
    fantasy_owner_name <- input$fantasy_owner_name
    fantasy_owner_email <- input$fantasy_owner_email
    fantasy_team_name <- input$fantasy_team_name
    paid <- input$paid_checkbox
    data.table("fantasy_owner_name" = fantasy_owner_name, 
      "fantasy_owner_email" = fantasy_owner_email, 
      "fantasy_team_name" = fantasy_team_name,
      "paid_checkbox" = paid)
  })
  
  download_btn_status <- reactive({
    all(
      participant_info()$fantasy_owner_name!="",
      str_detect(participant_info()$fantasy_owner_email,"[:graph:]{3,}@[:alnum:]{1,}\\.[:alnum:]{2,}"),
      participant_info()$fantasy_team_name!="",
      participant_info()$paid,
      length(positions_selected()) == 14L
    )
  })

  observeEvent(
    download_btn_status(),
    {
      if(download_btn_status()) {
        shinyjs::enable("download_roster")

      } else {
        shinyjs::disable("download_roster")
      }
    }
  )
  
  # create final roster for downloadHandler
  roster_data <- reactive({
    team_lookupstring_position %>%
      filter(lookup_string %in% roster$players) %>%
      select(position, team_abbr, lookup_string) %>% 
      mutate(
        `Fantasy Owner` = rep(participant_info()$fantasy_owner_name,14),
        `Fantasy Owner Email` = rep(participant_info()$fantasy_owner_email,14),
        `Fantasy Team Name` = rep(participant_info()$fantasy_team_name,14),
        `Roster` = 1:14,
        `Position Type` = if_else(position == "Defense", "Defense / Special teams", "Player"),
        `Automation Mapping` = if_else(
          position == "Defense", 
          team_abbr, 
          str_remove(str_remove(lookup_string, "^.*, ID: "),"\\)")
        ),
        `Check 1 - Selection is Unique` = TRUE,
        `Check 2 - Team is Unique` = TRUE
      ) %>% 
      group_by(
        position
      ) %>% 
      mutate(
        `Position Code` = if_else(position %in% c("QB","WR","TE","RB"), paste0(position,1:n()), 
                          if_else(position == "Defense", "D", position))
      ) %>% 
      ungroup() %>% 
      rename(
        `Position Group` = position,
        `Team Abbr.` = team_abbr,
        `Selection` = lookup_string
      ) %>%
      mutate(
        `Position Group` = case_when(
          `Position Code` == "K" ~ "SPEC", 
          `Position Code` %in% c("RB4","WR4","TE3") ~ "FLEX", 
          `Position Code` == "D" ~ "D", 
          .default = `Position Group`)
      ) %>% 
      select(
        `Fantasy Owner`,
        `Fantasy Owner Email`,
        `Fantasy Team Name`,
        `Automation Mapping`,
        `Roster`,
        `Position Type`,
        `Position Code`,
        `Position Group`,
        `Team Abbr.`,
        `Selection`,
        `Check 1 - Selection is Unique`,
        `Check 2 - Team is Unique`,
        everything()
      )
  })
  
  output$download_roster <- downloadHandler(
    filename = function() {
      paste0('Playoff Fantasy Roster ',Sys.time(), '.csv')
    },
    content = function(file) {
      write.csv(roster_data(), file, row.names = FALSE)
    }
  )
  
}


shinyApp(ui, server)
