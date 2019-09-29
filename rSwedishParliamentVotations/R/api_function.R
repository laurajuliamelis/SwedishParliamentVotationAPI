#' GET_votation
#'
#' \code{GET_votation} makes a GET request for data from the 
#' Swedish Parlament API, specifically for votations.
#' 
#' 
#' @param period a scalar or vector of year or years. The period year is defined as the year that starts of fiscal year e.g. 2018 for 2018/19. In vector form it will be e.g. [2018, 2019] will be 2018/19, 2019/20. If @param span is TRUE, then c(2017, 2019) will be evalutated as c(2017, 2018, 2019).
#' @param span boolean argument for setting span or not for @param period.
#' @param party string with the short names for the parties. E.g. "C" for Centerpartiet.
#' @param vote_result string with the possible results from the voting. Possible arguments are Ja, Nej, Avstår and Frånvarande.
#' @param rows integer defining the number of results to return from the query.
#'
#' @return \code{GET_votation} returns a dataframe from the query.
#'
#' @examples
#' GET_votation(period=2016, vote_result='Ja', rows=1)
#' GET_votation(party='C', rows=1)
#' 
#' @references \url{http://data.riksdagen.se/}
#'
#' @export
#' 


GET_votation <- function(period=NULL, span=FALSE, party=NULL, vote_result=NULL, rows=5){
  stopifnot(length(c(period, party, vote_result)) > 0, 
            is.numeric(rows) && rows > 0,
            is.numeric(period) || is.null(period),
            is.character(party) || is.null(party),
            is.character(vote_result) || is.null(vote_result),
            span == TRUE || span ==FALSE)
  
  # Base URL used for query
  path <- "http://data.riksdagen.se/voteringlista/?"
  
  # Handling of period query
  if(length(period) > 0){
    period_formatted <- vector()
    
    if(span){
      period <- period[1]:period[2]
    }
    
    for(p in period){
      period_formatted <- 
        append(period_formatted, paste0(p, '/', as.integer(substr(p, nchar(p)-2+1, nchar(p))) + 1))
    }
    period_query <- paste0("rm=", paste(period_formatted, sep='&rm=', collapse = ''), collapse = '')
  }else{
    period_query <- ''
  }
  
  # Handling of party query
  if(length(party) > 0){
    party_formatted <- vector()
    for(par in party){
      party_formatted <- append(party_formatted, par)
    }
    party_query <- 
      paste0("parti=", paste(party_formatted, sep='&parti=', collapse = ''), collapse = '')
    
    if(length(period) > 0){
      party_query <- paste0('&', party_query)
    }
  }else{
    party_query <- ''
  }
  
  # Handling of vote result query
  if(length(vote_result) > 0){
    vote_formatted <- vector()
    for(vote in vote_result){
      vote_formatted <- append(vote_formatted, vote)
    }
    vote_query <- 
      paste0("rost=", paste(vote_formatted, sep='&rost=', collapse = ''), collapse = '')
    
    if(length(period) > 0 || length(party) > 0){
      vote_query <- paste0('&', vote_query)
    }
  }else{
    vote_query <- ''
  }
  
  # Handling of rows query
  if(!length(period) > 0 && !length(party) > 0 && !length(vote_result) > 0){
    rows_query <- paste0("sz=", rows)
  }else{
    rows_query <- paste0("&sz=", rows)
  }
  
  # Create final URL including the fill query
  request <- paste0(path, period_query, party_query, vote_query, rows_query, "&utformat=xml", collapse = '')
  
  # Read the XML response at the URL
  response <- read_xml(request)
  
  # Extract all results in a dataframe
  df <- data.frame()
  i <- 1
  for(child in xml_children(response)){
    values <- vector()
    for(subchild in xml_children(child)){
      values <- append(values, xml_text(subchild))
    }
    df[i,1:length(values)] <- values
    i <- i+1
  }
  return(df)
}