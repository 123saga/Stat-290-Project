library(tidyverse)
library(data.table)
library(zoo)
library(lubridate)
trim <- function (x) gsub("^\\s+|\\s+$", "", x)
options(scipen = 999)
setwd("C:/Users/gsgr/Documents/SCPD/STATS290/Project/Stats-290-Project")

## function to get weather a data by location, all other params are optional
getPlotData  <- function(online=TRUE,
                            date="2017-01-01",
                            metric= "t_official"
                            )
{
  
  # Implement try-cath block to check inputs
  # format inputs
  from <- as.Date(date)
  to <- as.Date(date)+days(1)
  mtr <- as.character(metric)
  location_ids <- NA
  measures <- c("p_official","rh_std","solarad","t_max","t_min","t_official","windspd","ws_max")
  
  if(!(metric %in% measures)){
    print(paste0("Please enter a valid measure from: ",paste0(measures,collapse = ",")))
    
  } else {
    
    
    Locations <- readRDS("Distance_data_master.rda")
    
    ## get id for selected location
    locations <- unique(Locations%>%
      dplyr::select(id,latitude, longitude,state,location))
    
    location_ids <- unique(locations$id)
      
      # check offline falg
      if(online==FALSE){
        ## connect to rda file
        weather_data_master <- readRDS("weather_data.rda")
        
        weather_data <- weather_data_master%>%
          filter(metric==mtr)%>%
          filter(as.Date(time) == from)%>%
          group_by(id) %>%
          summarize(value=max(value)) %>%
          inner_join(locations, by=c("id"))
        
        ## return data
        if(nrow(weather_data)==0){
          print("No data avaiable for given input parameters, please check the values once again")
        }
        weather_data
        
      }else {
        
        ## make API call
        for (i in 1:length(location_ids)){
          loc_id<-location_ids[i]
          API_URL <- "https://www.ncdc.noaa.gov/crn/api/v1.0/sites/"
          API_URL_final<- paste0(API_URL,loc_id,
                                 "/data?start=",from,"T00:00Z&end=",to,
                                 "T00:00Z&metric=",mtr)
          
          
          data <- fromJSON(RCurl::getURL(API_URL_final))
          
          if(is.data.frame(data)){
            data <- data[,c("start","value","metric")]
            names(data) <- c("time","value","metric")
            data$id <- loc_id
            if(exists("weather_data")){
              weather_data <- rbind(weather_data,data)
            } else{
              weather_data <- data
            }
          }
          
          
        }
        ## return data
        if(!exists("weather_data")){
          print("No data avaiable for given input parameters, please check the values once again")
        }
        weather_data <- weather_data%>%
          group_by(id) %>%
          summarize(value=max(value)) %>%
          inner_join(locations, by=c("id"))
        
        weather_data
      } 
  }# end of input verification
}