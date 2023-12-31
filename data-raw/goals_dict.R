library(here)
library(readr)
library(dplyr)

metrics <- read_csv(here("data-raw", "metrics_config.csv"),
  col_types = cols(
    Goal = col_character(),
    Subgoal = col_character()
  )
) |>
  mutate(orientation_protect = case_when(
    orientation_protect == "Minimize" ~ "min",
    orientation_protect == "Maximize" ~ "max"
  )) |>
  mutate(orientation_restore = case_when(
    orientation_restore == "Minimize" ~ "min",
    orientation_restore == "Maximize" ~ "max"
  ))
fa
load("~/Documents/repos/king-county-retrofit-plan/data/subbasin_data.rda")

mean_data <- subbasin_data %>%
  select_if(is.numeric) %>%
  colMeans(na.rm = TRUE) %>%
  as.data.frame() %>%
  `colnames<-`("Indifference_abs") %>%
  rownames_to_column("Name")
# multiply threshold times mean value
metrics <- mean_data %>%
  as.data.frame() %>%
  merge(metrics)


# metrics <- set_names(metrics,goal_names)
#>
#> Attaching package: 'jsonlite'
#> The following object is masked from 'package:purrr':
#>
#>     flatten


#> # A tibble: 8 x 2
#>   A     B
#>   <chr> <chr>
#> 1 a     a
#> 2 a     b
#> 3 a     c
#> 4 b     d
#> 5 b     e
#> 6 b     f
#> 7 b     g
#> 8 c     h
#
# tb_nested = metrics |> mutate(Goal = paste0(Goal,". ",Goal_Description)) |>
#   group_by(Goal) |>
#   group_nest()
#
#
# goals_dict <- tb_nested$data |> as.list()
# names(goals_dict)<- goal_names
#
# subgoals_dict <- list()
# for( i in 1:nrow(tb_nested) ){
#   #get goals
#   goal_i <- goals_dict[[i]]
#   subgoal_tibble <- goal_i |> mutate(Subgoal = paste0(Subgoal,". ",Subgoal_Description)) |>
#     group_by(Subgoal) |>
#     group_nest()
#   subgoal_names <- subgoal_tibble$Subgoal
#   ll <- subgoal_tibble$data |> as.list()
#   names(ll)<- subgoal_names
#   subgoals_dict[[i]] <- ll
# }




# usethis::use_data(goals_dict,overwrite = TRUE)
# usethis::use_data(goals,overwrite = TRUE)
usethis::use_data(metrics, overwrite = TRUE)
