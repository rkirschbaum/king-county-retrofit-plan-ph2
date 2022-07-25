#' helpers
#'
#' @description A fct function
#'
#' @return The return value, if any, from executing the function.
#'
#' @noRd
plot_pref_flows <- function(pf2, adj_mat_numeric,name_col=NULL) {
  # build graph object from adjacency matrix
  g <-
    igraph::graph_from_adjacency_matrix(
      adj_mat_numeric,
      diag = FALSE,
      mode = "directed"
    )

  if(is.null(name_col)) {
    pf2<- pf2 %>% rownames_to_column('id')

    name_col <- 'id'
  }
  basins <- pf2[name_col]
  g.vis <- visNetwork::visIgraph(g)
  nodes <- g.vis$x$nodes
  edges <- g.vis$x$edges

  from_rank <- left_join(edges, pf2, by = c("from" = name_col))
  to_rank <- left_join(edges, pf2, by = c("to" = name_col))

  ranked_edges <- data.frame(edges,
                             from_rank = from_rank$rank,
                             to_rank = to_rank$rank
  )

  cleaned_edges <- ranked_edges %>%
    group_by(from) %>%
    slice(which.min(to_rank))


  lone_nodes_from <- basins[which(!basins %in% cleaned_edges$from)]

  lone_nodes_to <- ranked_edges %>%
    filter(!to %in% cleaned_edges$to) %>%
    group_by(to) %>%
    filter(from_rank == max(from_rank))

  add_in_nodes <- ranked_edges %>%
    add_row(lone_nodes_to)

  cleaned_edges <- cleaned_edges %>% rbind(lone_nodes_to)

  coords <- data.frame(
    x = pf2$phi_plus,
    y = pf2$phi_minus
  ) %>% as.matrix()

  # Rotate 45 degrees
  phi <- pi / 4

  rotation_matrix <- cbind(
    c(cos(phi), sin(phi)),
    c(-sin(phi), cos(phi))
  )

  rotated_coords <- coords %*% rotation_matrix

  nodes <- data.frame(id = basins,
                      label = basins,
                      rotated_coords,


                      title = paste0(
                                     "phi-: ",



                                     pf2$phi_minus,"<br>",
                                     "phi+: ",
                                     pf2$phi_plus, "<br>",
                                     "phi: ", pf2$score
                      ))


# Plot Graph --------------------------------------------------------------

  plot.graph <-
    visNetwork::visNetwork(nodes, cleaned_edges) %>%
    visNetwork::visEdges(arrows = "toshiny") %>%
    visNetwork::visOptions(highlightNearest = TRUE) %>%
    visNetwork::visIgraphLayout(
      #type = "full",
      #ayout = "layout.norm",
      layout="layout_as_tree",
      flip.y = FALSE,
      smooth = TRUE, physics = FALSE,
      layoutMatrix = rotated_coords
    ) %>%
    visNetwork::visNodes(
      shape = "box",
      fixed = list(y=TRUE),

      shadow = TRUE,

      `shapeProperties` = list(borderRadius = 5)
    ) %>%
   # visPhysics(stabilization = FALSE) %>%
    visNetwork::visPhysics(repulsion =  list(
      damping = 0.95))%>%
    visInteraction(dragNodes = FALSE)
    #visIgraphLayout()
  return(plot.graph)
}




make_summary_table <- function(data.df) {


  data <- data.df %>%
    pivot_longer(everything()) %>%
    group_by(name) %>%
    summarise(
      hist = list(hist(value,plot=FALSE)$count)[1],#$counts,# %>% jsonlite::toJSON(),
      mins = min(value) %>% signif(4) %>% format(big.mark = ','),
      maxs = max(value)%>% signif(4)%>% format(big.mark = ','),
      means =mean(value)%>% signif(4)%>% format(big.mark = ','),
      sdevs = sd(value)%>% signif(4)%>% format(big.mark = ',')
    ) %>%
    group_by(name) %>%
    mutate(
      chart =  jsonlite::toJSON(list(values = hist[[1]], options = list(type = "bar", bar.width=99))),
      selected = TRUE
      #minmax = "max",
      #weight = 0
    ) %>%
    select(-hist) %>%
    as.data.frame()







}



jitter_layout <- function(layout_matrix, tolerance=0.2 ){
  #check for overlapping nodes
  dups <- duplicated(layout_matrix)
  #move the x corridnate by tolerance time a random number
  for (i in 1:length(dups)) {
    if(dups[i]){
      layout_matrix[i,1] <- layout_matrix[i,1]*tolerance*runif(n=1,min=-1,max=1)
    }
  }
  return(layout_matrix)
}



plot_jittered_pref_flows <- function(pf2, adj_mat_numeric,name_col=NULL,tolerance=0.2) {
  # build graph object from adjacency matrix
  g <-
    igraph::graph_from_adjacency_matrix(
      adj_mat_numeric,
      diag = FALSE,
      mode = "directed"
    )

  if(is.null(name_col)) {
    pf2<- pf2 %>% rownames_to_column('id')

    name_col <- 'id'
  }
  basins <- pf2[name_col]
  g.vis <- visNetwork::visIgraph(g)
  nodes <- g.vis$x$nodes
  edges <- g.vis$x$edges

  from_rank <- left_join(edges, pf2, by = c("from" = name_col))
  to_rank <- left_join(edges, pf2, by = c("to" = name_col))

  ranked_edges <- data.frame(edges,
                             from_rank = from_rank$rank,
                             to_rank = to_rank$rank
  )

  cleaned_edges <- ranked_edges %>%
    group_by(from) %>%
    slice(which.min(to_rank))


  lone_nodes_from <- basins[which(!basins %in% cleaned_edges$from)]

  lone_nodes_to <- ranked_edges %>%
    filter(!to %in% cleaned_edges$to) %>%
    group_by(to) %>%
    filter(from_rank == max(from_rank))

  add_in_nodes <- ranked_edges %>%
    add_row(lone_nodes_to)

  cleaned_edges <- cleaned_edges %>% rbind(lone_nodes_to)

  coords <- data.frame(
    x = pf2$phi_plus,
    y = pf2$phi_minus
  ) %>% as.matrix()

  # Rotate 45 degrees
  phi <- pi / 4

  rotation_matrix <- cbind(
    c(cos(phi), sin(phi)),
    c(-sin(phi), cos(phi))
  )

  rotated_coords <- coords %*% rotation_matrix

  nodes <- data.frame(id = basins,
                      label = basins,
                      rotated_coords,


                      title = paste0(
                        "phi-: ",



                        pf2$phi_minus,"<br>",
                        "phi+: ",
                        pf2$phi_plus, "<br>",
                        "phi: ", pf2$score
                      ))


  # Plot Graph --------------------------------------------------------------

  plot.graph <-
    #make graph
    visNetwork::visNetwork(nodes, cleaned_edges) %>%
    #node options
    visNetwork::visNodes(
      shape = "box",
      fixed = list(y=TRUE),
      shadow = TRUE,
      `shapeProperties` = list(borderRadius = 5)
    ) %>%
    #edge options
    visNetwork::visEdges(arrows = "toshiny", physics = FALSE) %>%

    #layout options

    visNetwork::visIgraphLayout(
      #type = "full",
      layout = "layout.norm",
      #layout="layout_as_tree", flip.y = FALSE,
      smooth = TRUE, physics = FALSE,
      layoutMatrix = rotated_coords %>% jitter_layout(tolerance = tolerance)
    )%>%

    #vis options
    visOptions(
      highlightNearest = list(
        enabled = TRUE,
        algorithm = 'hierarchical',
        degree = list(from=0,to=99)))%>%

    visNetwork::visPhysics(minVelocity = 1, hierarchicalRepulsion = list(avoidOverlap = TRUE) )

  #visIgraphLayout()
  return(plot.graph)
}