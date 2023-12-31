criteria_page_UI2 <- function(id) {
  ns <- NS(id)
  tagList(
    fluidRow(
      # Column 1 Subbasin Prioritization------------------------------------------------------------
      column(
        width = 4,
        box(
          title = "Subbasin Prioritization", status = "primary",
          solidHeader = FALSE,
          width = NULL,
          ### box 1 Criteria Orientation -------------------------------------------------------------------
          box(
            title = "Criteria Orientation", status = "primary", width = NULL, solidHeader = TRUE,
            strong("Choose Orientation:"),
            radioButtons(
              inputId = ns("orientation_select"),
              label = NULL, # "Select Orientation",
              choices = c("Restoration", "Protection"),
              selected = "Restoration",
              inline = FALSE
            ),
            make_info(
              tagList(
                "Choose whether prioritization should focus on Restoration or Protection. Restoration will prioritize areas in need of improvement, while Protection will prioritize high functioning locations.",
                br(),
                a(tagList("See the StoryMap for more info", icon("external-link-alt")),
                  href = storymap_url
                )
              )
            )
          ),
          ### box 2 Criteria Weights -------------------------------------------------------------------
          box(
            width = NULL,
            title = "Criteria Weights", solidHeader = TRUE, status = "primary",
            helpText("Enter your preferred weight as a whole number between 0 and 5."),
            make_info("A weight of 0 indicates the metric
                      will be ignored. Metrics with missing data are not used."),
            hr(),
            make_numeric_inputs(goals, id),

            #
            column(
              width = 12,
              actionButton(ns("reset_weights"),
                width = "40%", label = "Reset",
                icon = icon("refresh")
              ),
              actionButton(ns("accept_weights"),
                width = "40%", label = "Accept",
                icon = icon("check")
              )
            )
          ),
          uiOutput(ns("count_missing"))
          ### box 3 Advanced Settings -------------------------------------------------------------------
          # box(
          #   width = NULL,
          #   title = "Advanced Settings", solidHeader = TRUE, status = "primary",
          # shinydashboardPlus::box(

          # dropdownMenu = boxDropdown(
          # boxPad(strong("Advanced Settings")),
          # boxPad(dev_pill()),
          #       fluidRow(column(
          #         width = 12,
          #         dev_pill(),
          #         # actionLink("Weight Subgoals", inputId = ns("apply_at_subgoal")),
          #         br(),
          #         # actionLink("Weight Criteria", inputId = ns("apply_at_criteria")),
          #         br()
          #         # actionLink("Edit Thresholds", inputId = ns("edit_thresholds"))
          #       ))
          #     )
          #   )
          # ),

          # end col ---------------------------------------------
        )
      ),
      # Column 2 ------------------------------------------------------------
      column(
        width = 8,
        ## Map -------------------------------------------------
        box(
          headerBorder = FALSE,
          title = "Results", status = "primary", width = NULL,
          shinyWidgets::panel(
            leafletOutput(ns("map"), height = 600)
          )
        ),
        ## results tabset --------------------------------------
        ### mcda results ----------------------------------------
        shinydashboard::tabBox(
          width = NULL,
          tabPanel(
            width = 12, title = "Results Table",
            shinyWidgets::panel(
              DTOutput(ns("mcda_results"))
            )
          ),
          ### results by goal -------------------------------------
          tabPanel(
            width = 12,
            title = "Chart Results by Goal",
            shinycssloaders::withSpinner(
              apexfacetOutput(ns("uc_goals"))
            )
          ),
          tabPanel(
            width =12, title = "Download Report",
            downloadButton(ns('download_excel'),label = "Download Excel Report")
          )
        )
      )
      # end column 2 ----------------------------------------
    )
  )
}



criteria_page_server2 <- function(id, rv2) {
  moduleServer(
    id,
    function(input, output, session) {
      ns <- NS(id)



      all_metrics <- reactive({
        metrics
      })
      goals <- metrics %>%
        select(Goal, Goal_Description) %>%
        unique() %>%
        arrange(Goal)

# Process data passed from previous page --------------

      ## select numeric criteria only  ------------------------------
      cleaned_criteria <- reactive({
        rv2$filtered_data %>% select_if(is.numeric)
      })

      ## count missing data  ------------------------------
      output$count_missing <- renderUI({
        shinydashboardPlus::box(
          headerBorder = FALSE, # icon = icon("warning",style='color: black'),
          collapsed = FALSE,
          title = div(tagList((na_cols() %>% length()), "metrics have missing data"), style = "color: black"),
          closable = TRUE,
          width = NULL,
          status = "warning",
          solidHeader = TRUE,
          collapsible = FALSE,
          tagList(
            "Only metrics with available data for all selected subbasins (Pre-Screening tab) are analyzed. The following metrics have been discarded due to missing data:", br(),
            br(),
            # HTML('<ul class="list-group>'),
            HTML("<li class='list-group-item'>"),
            HTML(paste(na_cols() %>% get_pretty_names(),
              collapse = "<li class='list-group-item'>"
            )),
          )
          # actionLink(ns('view_missing'),label = 'Click to view')
        )
      })


# Advanced editing (not used.  For future tool --------
      #output$modal_info <- renderUI({
        # tagList(
        #   HTML(paste0("This is some HTML")),
        #   radioButtons(
        #     inputId = ns("goal_tiers_select"),
        #     label = "Select tier to apply weights",
        #     choices = c("Criteria", "Subgoals"),
        #     selected = "Subgoals",
        #     inline = TRUE
        #   )
        # )
      #})

      # user_table <- reactive({
      #   if (input$apply_at_subgoal) {
      #     sub_goal_metrics()
      #   } else {
      #     all_metrics()
      #   }
      # })



      ## Advanced Edit subgoals --------------------------------------------------


      # output$sub_goal_metrics_modal <-
      #   renderUI({
      #     output$advanced_subgoal_table <- renderRHandsontable(rhandsontable(sub_goal_metrics()))
      #     tagList(
      #       rHandsontableOutput(ns("advanced_subgoal_table"))
      #     )
      #   })
      #
      # observe({
      #   showModal(modalDialog(
      #     easyClose = TRUE,
      #     size = "l", footer = tagList(
      #       modalButton("Cancel"),
      #       actionButton("ok", "OK")
      #     ),
      #     htmlOutput(ns("modal_info")), htmlOutput(ns("sub_goal_metrics_modal"))
      #   ))
      # }) %>% bindEvent(input$apply_at_subgoal)
      #
      #
      # ## Advanced edit criteria --------------------------------------------------
      #
      #
      # output$criteria_metrics_modal <-
      #   renderUI({
      #     output$advanced_criteria_table <- renderRHandsontable(rhandsontable(user_edits_all_metrics()))
      #     tagList(
      #       rHandsontableOutput(ns("advanced_criteria_table"))
      #     )
      #   })
      #
      #
      # observe({
      #   showModal(modalDialog(
      #     easyClose = TRUE,
      #     size = "l", footer = tagList(
      #       modalButton("Cancel"),
      #       actionButton("ok", "OK")
      #     ),
      #     htmlOutput(ns("modal_info")), htmlOutput(ns("criteria_metrics_modal"))
      #   ))
      # }) %>% bindEvent(input$apply_at_criteria)

      criteria_names <- reactive(cleaned_criteria() %>% colnames())
      alternatives <- reactive(cleaned_criteria() %>% rownames())
      row_count <- reactive(nrow(cleaned_criteria()))

      all_metrics <- reactive({
        metrics %>%
          dplyr::filter(Name %in% criteria_names())
      })

# Get user inputs -------------------------------------


      ## Get user weights ----------------------------------------------------------


      # validator for weights

      iv <- InputValidator$new()
      iv$add_rule("goal1", sv_between(0, 5))
      iv$add_rule("goal2", sv_between(0, 5))
      iv$add_rule("goal3", sv_between(0, 5))
      iv$add_rule("goal4", sv_between(0, 5))
      iv$enable()
      user_weights.df <- reactive({
        data.frame(
          Goal = goals$Goal,
          Name = goals$Goal_Description,
          Weight = user_weights()
        )
      })

      user_edits_all_metrics <- reactive({
        merge(
          all_metrics() %>%
            select("Criteria_Name" = "Name", "Goal", "Metric_no", "orientation_protect", "orientation_restore", "Indifference_Threshold_Percentage"),
          user_weights.df(),
          by.x = "Goal", by.y = "Goal"
        )
      })

      ## Clean user inputs for mcda ----------------------------------------------
      cleaned_list <- reactive(remove_nas_from_pt(pt.df = cleaned_criteria()))
      cleaned_pt <- reactive(cleaned_list()[["cleaned_pt"]])
      na_cols <- reactive(cleaned_list()[["na_cols"]])

      cleaned_user_table <- reactive({
        clean_mcda_inputs(
          ex_user_metrics = user_edits_all_metrics(),
          na_cols = na_cols()
        )
      })





## get user min max ------------------------------------
      min_max.df <- reactive({
        if (isTRUE(input$orientation_select == "Protection")) {
          data.frame(min_max = cleaned_user_table()[["orientation_protect"]])
        } else {
          data.frame(min_max = cleaned_user_table()[["orientation_restore"]])
        }
      })

      min_max.vec <- reactive({
        if (input$orientation_select == "Protection") {
          cleaned_user_table()[["orientation_protect"]]
        } else {
          cleaned_user_table()[["orientation_restore"]]
        }
      })


      ## Get user edited weights -------------------------------------------------
      user_weights <- reactive(
        c(input$goal1, input$goal2, input$goal3, input$goal4)
      )

      # Calc Weighted Sum -------------------------------------------------------

      weights_oriented <- reactive({
        orient_weights(
          minmax = min_max.vec(),
          weights = cleaned_user_table()[["Weight"]]
        )
      })

      top_PT <- reactive({
        scaled_weighted_sum(
          performanceTable = cleaned_pt(),
          weights = weights_oriented()
        )
      })

      output$top_basins <- renderDT(
        datatable(
          top_PT() %>% sig_figs(3),
          colnames = colnames(top_PT()) %>% get_pretty_names(),
          extensions = c("Buttons", "FixedColumns"),
          options = list(
            scrollX = TRUE,
            fixedColumns = TRUE,
            dom = "tiplrB",
            buttons = c("copy", "csv", "excel")
          )
        )
      )

      output$user_edits_all_metrics <- renderDT(datatable(
        user_edits_all_metrics(),
        extensions = c("Buttons", "FixedColumns"),
      ))
      output$min_max.vec <- renderDT(min_max.vec() %>% as.data.frame())


# get mcda results ------------------------------------

      mcda_results <- reactive({
        return(
          promethee_2(
            dataset = top_PT() %>% dplyr::select(-weighted_sum_score),
            weighting = cleaned_user_table()[["Weight"]], #
            minmax = min_max.vec(),
            IndT = cleaned_user_table()[["Indifference_abs"]],
            limit = return_vals
          )
        )
      }) %>% bindEvent(input$accept_weights, ignoreInit = TRUE)


      # Generate outputs outputs -----------------------------------------------------------------
      output$count_items <- renderUI({
        card(.num = rv2$filtered_data %>% nrow(), .description = "Total Subbasins")
      })

      ## tables ------------------------------------------------------------------
      out_tables <- reactive(
        user_edits_all_metrics()
      )


      ### reports -----------------------------------------------------------------
      output$scenario <- renderText(input$orientation_select)
      output$report1 <- renderDT(user_weights.df())
      output$report2 <- renderDT(mcda_results()[["UnicriterionNetFlows"]])

      results_data <- reactive(mcda_results()[["out_flows"]] %>%
        select(c(score, score_rank)) %>%
        rownames_to_column("SWSID") %>%
        relocate(score_rank, .before = 1))
      ### mcda results datatable -----------------------------------------------------------------
      output$mcda_results <- renderDT(
        datatable(
          results_data(),
          rownames = FALSE,
          colnames = c("Rank", "SWSID", "Score"),
          extensions = "Buttons",
          selection = "single"
        ) %>% formatStyle("score",
          background = styleColorBar(c(-1, 1), "#81A1C1", angle = -90),
          backgroundSize = "98% 88%",
          backgroundRepeat = "no-repeat",
          backgroundPosition = "center"
        )
      )










### table2 ----------------------------------------------
      output$tbl2 <- renderDT(
        mcda_results()[["out_flows"]] %>%
          rownames_to_column("SWSID") %>%
          relocate(score_rank, .before = 1)
      )


      # top items to return
      return_vals <- 9

      pf2_outflows <- reactive(mcda_results()[["out_flows"]])




      ## map ------------------------------------------------------------------

      top_shps <- reactive(
        subbasin_shps %>% merge(pf2_outflows() %>% rownames_to_column("SWSID"))
      )
      # Create a continuous palette function

      values <- reactive(pf2_outflows()[["score"]])

      map.pal.fun <- reactive((colorBin(king_co_palette, values(), 5, pretty = TRUE, reverse = FALSE)))

      pal.rev.fun <- reactive((colorBin(king_co_palette, values(), 5, pretty = TRUE, reverse = TRUE)))

      output$map <-
        renderLeaflet({
          basemap %>%
            addPolygons(
              color = "#28a745",
              data = rv2$filtered_shps,
              fillOpacity = 0.2, opacity = 0.8,
              fillColor = "grey",
              weight = 0.4
            )
        })
#
      observe({
        map.pal <- (colorBin(king_co_palette, values(), 5, pretty = TRUE, reverse = FALSE))
        pal.rev <- (colorBin(king_co_palette, values(), 5, pretty = TRUE, reverse = TRUE))

### update map with scores ------------------------------


        leafletProxy("map") %>%
          clearGroup("top_sheds") %>%
          leaflet::removeControl("legend") %>%
          addPolygons(
            data = top_shps(), group = "top_sheds", layerId = ~SWSID,
            label = ~score_rank,
            labelOptions = labelOptions(
              noHide = TRUE, textOnly = TRUE,
              permanent = TRUE
            ),
            weight = 1,
            color = "white",
            opacity = 1,
            fillColor = ~ map.pal(score),
            fillOpacity = 0.75,
            popup = ~ paste(
              strong("Subbasin:"), SWSID, "<br>", strong("Score:"), score,
              "<br>", strong("Rank:"), score_rank
            ),
            highlightOptions = highlightOptions(
              weight = 5, bringToFront = T, opacity = 1,
              color = "yellow"
            )
          ) %>%
          addLegend(
            layerId = "legend", pal = pal.rev, values = values(), opacity = 0.7, title = "Score",
            position = "bottomleft",
            labFormat = labelFormat(transform = function(x) sort(x, decreasing = TRUE))
          )
      }) %>% bindEvent(input$accept_weights, ignoreInit = TRUE)

# cross talk observers --------------------------------

## table observer --------------------------------------
      observeEvent(input$mcda_results_rows_selected, {

        basin_list <-eventReactive(input$mcda_results_rows_selected, {
          mcda_results()[["out_flows"]] %>% rownames()
        })

        selected_ids <- reactive(basin_list()[input$mcda_results_rows_selected])


        selected_shps <- eventReactive(input$mcda_results_rows_selected, {
          top_shps() %>% filter(SWSID == selected_ids())
        })

        bbox <- reactive(st_bbox(selected_shps()) %>%
                           as.vector())
        #
        cent <- reactive(do.call(rbind, st_geometry(selected_shps()) %>% st_centroid()))

        leafletProxy('map') %>%
          clearGroup("selected") %>%
          addPolygons(data = selected_shps(),color = 'yellow',group = "selected") %>%
          flyToBounds(bbox()[1], bbox()[2], bbox()[3], bbox()[4])


      })



## map observer ----------------------------------------
      # observer for map click ------------------------------
      observeEvent(input$map_shape_click,
                   {
                     map_click_info<- eventReactive(input$map_shape_click,{
                       input$map_shape_click
                     })
#check to see if id is in table
                     click_id <- reactive(input$map_shape_click$id)
                     if(!is.null(click_id())){

                     print(click_id())
                     }

                     #update map
                     map_click_shp <- reactive(
                       top_shps() %>% filter(SWSID ==
                                              map_click_info()['id']))
# #update map
leafletProxy('map') %>%
                       clearGroup("selected") %>%

                       addPolygons(data = map_click_shp(),color = 'yellow',group = "selected")

# #update table
#
DT::dataTableProxy("mcda_results") %>%
                       selectRows(
                         which(results_data()['SWSID'] == click_id()))
                   }
      )

      # Charts ------------------------------------------------------------------

      ## Unicriterion Net flow Chart -----------------------------------------------------------
      uc.df <- reactive(mcda_results()[["UnicriterionNetFlows"]] %>%
        rownames_to_column("SWSID"))
      observe(print(uc.df()))

      output$uc_goals <-
        renderApexfacet(
          uc_goal_chart(uc.df())
        )



# Download Handler ------------------------------------

      output$download_excel <- downloadHandler(
        #make list of tables to add
        filename = function() {
          paste0("subbasin_prioritization_",Sys.Date(),".xlsx")
        },
        content = function(file) {
          tables = reactive({
            list(
                User_weights = user_weights.df(),
                Criteria = cleaned_criteria() %>% round(4) %>%
                  rownames_to_column("SWSID"),
                Ranking = results_data(),
                out_flows = mcda_results()[["out_flows"]]%>%
                  rownames_to_column("SWSID"),
                Unicriterion_net_flows = mcda_results()[["UnicriterionNetFlows"]]%>%
                  rownames_to_column("SWSID") %>% t()
            )
            })
          my_workbook = generate_reports(tables())
          #insert title page
          addWorksheet(my_workbook,sheetName = 'Summary')
          writeData(wb = my_workbook,sheet = 6,
                    x = c("Subbasin Prioritization Report",
                          "King County Stormwater Retrofit Planner",
                          "https://geosyn.shinyapps.io/king-county-retrofit-plan/",
                          paste("Report Date:",Sys.Date() %>% as.character())
                    )
          )
#style first page
          style1 <- createStyle(border = "TopBottom", borderColour = "#4F81BD",fontSize = 18,
                                textDecoration = 'bold')
          addStyle(my_workbook, sheet = 6, style1, rows = 1, cols = 1:4)

          #move summary to first sheet

          worksheetOrder(my_workbook)<-c(6,1,2,3,4,5)
          saveWorkbook(my_workbook, file)
        }
      )


})}


ui <- dashboardPage(
  header = dashboardHeader(), sidebar = dashboardSidebar(), body =
    dashboardBody(
      use_theme(kingco_theme),
      criteria_page_UI2("test")
    )
)

test_basins <- subbasin_data %>%
  select_if(is.numeric) %>%
  mutate(BIBI = 0) %>%
  mutate(Sidewalk_Density = 0)



server <- function(input, output, session) {
  rv2 <- reactiveValues(
    # base_data = test_basins,
    filtered_data = subbasin_data, # %>% na.omit(),
    filtered_shps = subbasin_shps
  )
  criteria_page_server2("test", rv2)
}

shinyApp(ui, server)
