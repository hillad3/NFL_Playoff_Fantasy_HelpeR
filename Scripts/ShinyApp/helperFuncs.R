require(data.table)

order_cols <- function(dt, pos){

  basic_order <- c(
    'position',
    'lookup_string',
    'week',
    'season_type',
    'player_id',
    'player_name',
    'team_abbr',
    'team_conf',
    'team_division',
    'stat_type',
    'stat_label',
    'stat_values'
  )

  qb_order <- c(
    'passing_tds__fantasy_points',
    'passing_tds__football_values',
    'passing_yards__fantasy_points',
    'passing_yards__football_values',
    'rushing_tds__fantasy_points',
    'rushing_tds__football_values',
    'rushing_yards__fantasy_points',
    'rushing_yards__football_values',
    'interceptions__fantasy_points',
    'interceptions__football_values',
    'sack_fumbles_lost__fantasy_points',
    'sack_fumbles_lost__football_values',
    'rushing_fumbles_lost__fantasy_points',
    'rushing_fumbles_lost__football_values',
    'passing_2pt_conversions__fantasy_points',
    'passing_2pt_conversions__football_values',
    'receiving_tds__fantasy_points',
    'receiving_tds__football_values',
    'receiving_yards__fantasy_points',
    'receiving_yards__football_values',
    'receiving_2pt_conversions__fantasy_points',
    'receiving_2pt_conversions__football_values',
    'receiving_fumbles_lost__fantasy_points',
    'receiving_fumbles_lost__football_values',
    'rushing_2pt_conversions__fantasy_points',
    'rushing_2pt_conversions__football_values',
    '40yd_pass_td_qb_bonus__fantasy_points',
    '40yd_pass_td_qb_bonus__football_values',
    '40yd_pass_td_receiver_bonus__fantasy_points',
    '40yd_pass_td_receiver_bonus__football_values',
    '40yd_rush_td_bonus__fantasy_points',
    '40yd_rush_td_bonus__football_values'
  )

  rb_order <- c(
    'rushing_tds__fantasy_points',
    'rushing_tds__football_values',
    'rushing_yards__fantasy_points',
    'rushing_yards__football_values',
    'rushing_2pt_conversions__fantasy_points',
    'rushing_2pt_conversions__football_values',
    'rushing_fumbles_lost__fantasy_points',
    'rushing_fumbles_lost__football_values',
    'passing_tds__fantasy_points',
    'passing_tds__football_values',
    'receiving_tds__fantasy_points',
    'receiving_tds__football_values',
    'passing_yards__fantasy_points',
    'passing_yards__football_values',
    'receiving_yards__fantasy_points',
    'receiving_yards__football_values',
    'passing_2pt_conversions__fantasy_points',
    'passing_2pt_conversions__football_values',
    'receiving_2pt_conversions__fantasy_points',
    'receiving_2pt_conversions__football_values',
    'receiving_fumbles_lost__fantasy_points',
    'receiving_fumbles_lost__football_values',
    'sack_fumbles_lost__fantasy_points',
    'sack_fumbles_lost__football_values',
    'interceptions__fantasy_points',
    'interceptions__football_values',
    '40yd_pass_td_qb_bonus__fantasy_points',
    '40yd_pass_td_qb_bonus__football_values',
    '40yd_pass_td_receiver_bonus__fantasy_points',
    '40yd_pass_td_receiver_bonus__football_values',
    '40yd_rush_td_bonus__fantasy_points',
    '40yd_rush_td_bonus__football_values',
    '40yd_return_td_bonus__fantasy_points',
    '40yd_return_td_bonus__football_values'
  )

  te_order <- c(
    'receiving_tds__fantasy_points',
    'receiving_tds__football_values',
    'receiving_yards__fantasy_points',
    'receiving_yards__football_values',
    'receiving_2pt_conversions__fantasy_points',
    'receiving_2pt_conversions__football_values',
    'receiving_fumbles_lost__fantasy_points',
    'receiving_fumbles_lost__football_values',
    'passing_tds__fantasy_points',
    'passing_tds__football_values',
    'rushing_tds__fantasy_points',
    'rushing_tds__football_values',
    'passing_yards__fantasy_points',
    'passing_yards__football_values',
    'rushing_yards__fantasy_points',
    'rushing_yards__football_values',
    'passing_2pt_conversions__fantasy_points',
    'passing_2pt_conversions__football_values',
    'rushing_2pt_conversions__fantasy_points',
    'rushing_2pt_conversions__football_values',
    'rushing_fumbles_lost__fantasy_points',
    'rushing_fumbles_lost__football_values',
    'sack_fumbles_lost__fantasy_points',
    'sack_fumbles_lost__football_values',
    'interceptions__fantasy_points',
    'interceptions__football_values',
    '40yd_pass_td_qb_bonus__fantasy_points',
    '40yd_pass_td_qb_bonus__football_values',
    '40yd_pass_td_receiver_bonus__fantasy_points',
    '40yd_pass_td_receiver_bonus__football_values',
    '40yd_rush_td_bonus__fantasy_points',
    '40yd_rush_td_bonus__football_values',
    '40yd_return_td_bonus__fantasy_points',
    '40yd_return_td_bonus__football_values'
  )

  wr_order <- c(
    'receiving_tds__fantasy_points',
    'receiving_tds__football_values',
    'receiving_yards__fantasy_points',
    'receiving_yards__football_values',
    'receiving_fumbles_lost__fantasy_points',
    'receiving_fumbles_lost__football_values',
    'receiving_2pt_conversions__fantasy_points',
    'receiving_2pt_conversions__football_values',
    'passing_tds__fantasy_points',
    'passing_tds__football_values',
    'rushing_tds__fantasy_points',
    'rushing_tds__football_values',
    'passing_yards__fantasy_points',
    'passing_yards__football_values',
    'rushing_yards__fantasy_points',
    'rushing_yards__football_values',
    'passing_2pt_conversions__fantasy_points',
    'passing_2pt_conversions__football_values',
    'rushing_2pt_conversions__fantasy_points',
    'rushing_2pt_conversions__football_values',
    'rushing_fumbles_lost__fantasy_points',
    'rushing_fumbles_lost__football_values',
    'sack_fumbles_lost__fantasy_points',
    'sack_fumbles_lost__football_values',
    'interceptions__fantasy_points',
    'interceptions__football_values',
    '40yd_pass_td_qb_bonus__fantasy_points',
    '40yd_pass_td_qb_bonus__football_values',
    '40yd_pass_td_receiver_bonus__fantasy_points',
    '40yd_pass_td_receiver_bonus__football_values',
    '40yd_rush_td_bonus__fantasy_points',
    '40yd_rush_td_bonus__football_values',
    '40yd_return_td_bonus__fantasy_points',
    '40yd_return_td_bonus__football_values'
  )

  k_order <- c(
    'fg_made__fantasy_points',
    'fg_made__football_values',
    'pat_made__fantasy_points',
    'pat_made__football_values',
    'fg_missed__fantasy_points',
    'fg_missed__football_values',
    'fg_made_40_49__fantasy_points',
    'fg_made_40_49__football_values',
    'fg_made_50___fantasy_points',
    'fg_made_50___football_values',
    'fg_blocked__fantasy_points',
    'fg_blocked__football_values',
    'pat_missed__fantasy_points',
    'pat_missed__football_values'
  )

  defense_order <- c(
    'def_points_allowed__fantasy_points',
    'def_points_allowed__football_values',
    'def_td__fantasy_points',
    'def_td__football_values',
    'def_kickoff_return_td__fantasy_points',
    'def_kickoff_return_td__football_values',
    'def_punt_return_td__fantasy_points',
    'def_punt_return_td__football_values',
    'def_sack__fantasy_points',
    'def_sack__football_values',
    'def_fumble_recovery__fantasy_points',
    'def_fumble_recovery__football_values',
    'def_fumble_recovery_punt__fantasy_points',
    'def_fumble_recovery_punt__football_values',
    'def_interception__fantasy_points',
    'def_interception__football_values',
    'def_safety__fantasy_points',
    'def_safety__football_values',
    'def_block__fantasy_points',
    'def_block__football_values'
  )

  if(pos == "QB"){
    master_order <- c(basic_order, qb_order)
  } else if(pos == "RB"){
    master_order <- c(basic_order, rb_order)
  } else if(pos == "TE"){
    master_order <- c(basic_order, te_order)
  } else if(pos == "WR"){
    master_order <- c(basic_order, wr_order)
  } else if(pos == "K"){
    master_order <- c(basic_order, k_order)
  } else if(pos == "Defense"){
    master_order <- c(basic_order, defense_order)
  } else {
    print("Error: pos did not evaluate to a valid value")
  }

  if(any(duplicated(master_order))){
    print(paste0("There are duplicated columns in the ", str_lower(pos),"_order"))
    print(paste0(master_order[duplicated(master_order)], collapse = "; "))
  }

  found_order <- names(dt)

  unmapped_cols <- found_order[!(found_order %in% master_order)] |> sort()

  if(length(unmapped_cols)){
    print(paste0("There are unmapped ", pos, " columns in the dataset"))
    print(paste0(unmapped_cols, collapse = "; "))
  }

  preferred_order <- master_order[master_order %in% found_order]

  return(dt[,..preferred_order])

}

sort_cols <- function(dt, pos, stat_type){

  if(pos == "QB" & stat_type %in% c("Fantasy Points", "Both")){
    setorder(dt, -passing_tds__fantasy_points)
  } else if(pos == "QB" & stat_type == "Football Values"){
    setorder(dt, -passing_tds__football_values)
  } else if(pos == "RB" & stat_type %in% c("Fantasy Points", "Both")){
    setorder(dt, -rushing_tds__fantasy_points)
  } else if(pos == "RB" & stat_type == "Football Values"){
    setorder(dt, -rushing_tds__football_values)
  } else if(pos == "WR" & stat_type %in% c("Fantasy Points", "Both")){
    setorder(dt, -receiving_tds__fantasy_points)
  } else if(pos == "WR" & stat_type == "Football Values"){
    setorder(dt, -receiving_tds__football_values)
  } else if(pos == "TE" & stat_type %in% c("Fantasy Points", "Both")){
    setorder(dt, -receiving_tds__fantasy_points)
  } else if(pos == "TE" & stat_type == "Football Values"){
    setorder(dt, -receiving_tds__football_values)
  } else if(pos == "K" & stat_type %in% c("Fantasy Points", "Both")){
    setorder(dt, -fg_made__fantasy_points)
  } else if(pos == "K" & stat_type == "Football Values"){
    setorder(dt, -fg_made__football_values)
  } else if(pos == "Defense" & stat_type %in% c("Fantasy Points", "Both")){
    setorder(dt, -def_points_allowed__fantasy_points)
  } else if(pos == "Defense" & stat_type == "Football Values"){
    setorder(dt, -def_points_allowed__football_values)
  }

  return(dt)

}

update_app_stats <- function(dt,
                             pos,
                             reg_or_post,
                             stat_type,
                             stat_teams,
                             is_summed_stat,
                             is_wide_table){

  if(!(pos %in% c("K","QB","RB","TE","WR","Defense"))){
    print(paste0(pos, " is not a valid position"))
  }

  dt <- dt[position == pos]
  dt <- dt[season_type == reg_or_post]
  dt <- dt[team_abbr %in% stat_teams]

  # this returns an empty data.table if there are no stats, which avoids an error when casting
  if(dim(dt)[1]==0L){
    return(dt)
  }

  if(stat_type=="Football Values"){
    dt <- dt[stat_type=="football_values"]
  } else if (stat_type=="Fantasy Points"){
    dt <- dt[stat_type=="fantasy_points"]
  }

  if(is_summed_stat){

    dt <- dt[, week:=NULL]

    grouping_by <- c(
      'position',
      'season_type',
      'lookup_string',
      'player_id',
      'player_name',
      'team_abbr',
      'team_conf',
      'team_division',
      'stat_type',
      'stat_label'
    )

    dt <- dt[, by = grouping_by, .(stat_values = sum(stat_values))]

  }

  dt[,stat_label := paste0(stat_label,"__",stat_type)]

  if(!is_summed_stat && !is_wide_table){

    col_order <- c(
      'position',
      'lookup_string',
      'week',
      'season_type',
      'player_id',
      'player_name',
      'team_abbr',
      'team_conf',
      'team_division',
      'stat_type',
      'stat_label',
      'stat_values'
    )

    dt <- dt[,.SD, .SDcols = col_order]
    setorder(dt, position, player_id, week)

  } else if(is_summed_stat && !is_wide_table){

    col_order <- c(
      'position',
      'lookup_string',
      'season_type',
      'player_id',
      'player_name',
      'team_abbr',
      'team_conf',
      'team_division',
      'stat_type',
      'stat_label',
      'stat_values'
    )

    dt <- dt[,.SD, .SDcols = col_order]
    setorder(dt, position, -stat_values)

  } else if(is_summed_stat && is_wide_table){
    # does not include the `week` variable when summarized
    # value.var is unspecified since football_values and fantasy_points may or may not be presents
    dt <- dcast(
      dt,
      position + season_type + lookup_string + player_id + player_name + team_abbr + team_conf + team_division ~ stat_label,
      value.var = c("stat_values"),
      fill = 0
    )
    dt <- order_cols(dt, pos)
    dt <- sort_cols(dt, pos, stat_type)
  } else if(!is_summed_stat && is_wide_table) {
    dt <- dcast(
      dt,
      position + week + season_type + lookup_string + player_id + player_name + team_abbr + team_conf + team_division ~ stat_label,
      value.var = c("stat_values"),
      fun.aggregate = sum, # this is required, otherwise it will report the length instead of totaling where duplicate stats exist
      fill = 0
    )
    dt <- order_cols(dt, pos)
    dt <- sort_cols(dt, pos, stat_type)
  }

  return(dt)

}

update_app_totals <- function(dt,
                             pos,
                             stat_teams){
  
  if(!(pos %in% c("K","QB","RB","TE","WR","Defense","All"))){
    print(paste0(pos, " is not a valid position"))
  }
  
  dt <- dt[season_type == "Post"]
  dt <- dt[stat_type=="fantasy_points"]
  if(pos != "All"){
    dt <- dt[position == pos]
  }
  dt <- dt[team_abbr %in% stat_teams]
  
  
  # this returns an empty data.table if there are no stats, which avoids an error when casting
  if(dim(dt)[1]==0L){
    return(dt)
  }
  
  grouping_by <- c(
    'position',
    'week',
    'player_id',
    'player_name',
    'team_abbr'
  )
  
  dt <- dt[, by = grouping_by, .(stat_values = sum(stat_values))]
    
  dt <- dcast(
    dt,
    position + team_abbr + player_name + player_id ~ week,
    value.var = c("stat_values"),
    fill = 0
  )
  
  point_cols <- c("19","20","21","22")[c("19","20","21","22") %in% names(dt)]
  dt <- dt |>
    group_by(player_id) |> 
    mutate(fantasy_points = rowSums(across(where(is.numeric)))) |> 
    ungroup() |> 
    as.data.table()
  
  dt <- setorder(dt, -fantasy_points)
  dt[,player_id:=NULL]
  
  possible_cols <-
    c(
      "position",
      "team_abbr",
      "player_name",
      "19",
      "20",
      "21",
      "22",
      "fantasy_points"
    )
  
  new_names <- 
    c(
      "Position",
      "Team Abbr.",
      "Player Name",
      "Wild Card (Week 1)",
      "Divisional (Week 2)",
      "Conference (Week 3)",
      "Superbowl (Week 4)",
      "Total Points"
    )
  
  new_names <- new_names[possible_cols %in% names(dt)]
  
  setnames(dt, new = new_names)
  
  return(dt)
  
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


get_last_csv <- function(key){
  # this funciton should get the latest csv file in the data folder
  # provided it matches with the key provided
  f <- list.files(path = "data")
  f <- f[str_detect(f, paste0("^",key))]
  d <- str_extract(f,"[:digit:]{4}-[:digit:]{2}-[:digit:]{2} [:digit:]{6}")
  f <- f[d == str_remove_all(as.character(max(as_datetime(d))),":")]
  return(paste0("data/",f))
}