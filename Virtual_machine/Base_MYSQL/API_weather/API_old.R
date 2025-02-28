library(RCurl)
library(jsonlite)
library(data.table)
library(RJDBC)

setwd("D:/Cronus/Virtual_machine/Base_MYSQL/API_weather")
getwd()


# ID всех городов
#  all_city_id <- fromJSON("city.list.json")
#  as.data.table(all_city_id)
#  all_city_id$lon<- all_city_id$coord$lon
#  all_city_id$lat<- all_city_id$coord$lat
# all_city_id$coord <- NULL

# API key
key <- "bab64f8cbd90271f5da08e40a4f4e968"

api_forecatby_id <- "api.openweathermap.org/data/2.5/forecast?id="
city_id <- "797062"

# прогноз на 5 дней по 3 часа
zapros <- paste0(api_forecatby_id,city_id,"&units=metric","&APPID=",key)  
a<- fromJSON(getURL(zapros))

# Информация о городе
city<- unlist(a$city)

# Инфомарция о погоде главная часть
weather_main<- a$list$main

# Инфомарция о погоде погодные условия
weather_weather <- a$list$weather[[1]]
for(i in a$list$weather) {
  weather_weather <- rbind(weather_weather,i)
}
weather_weather <- weather_weather[2:nrow(weather_weather),]
row.names(weather_weather) <- 1:nrow(weather_weather)

# Инфомарция о погоде облачность
weather_clouds<- a$list$clouds

# Инфомарция о погоде скорость ветра
weather_wind <- a$list$wind

# Инфомарция о погоде возможные обьем осадков
weather_rain<- a$list$rain
names(weather_rain) <- "rain"

# Инфомарция о погоде возможные обьем осадков снега
# list.rain.3h Rain volume for last 3 hours

if (any(names(a$list)%in%"snow")) {
  weather_snow<- a$list$snow
  names(weather_snow) <- "snow"  
} else {
   
  weather_snow <- as.data.frame(rep("NULL",nrow(a$list)))
    names(weather_snow) <- "snow"
    weather_snow$snow <- as.character(weather_snow$snow)
  }

# НЕЗНАЮ
weather_sys<- a$list$sys

#Инфомарция о погоде Дата и час погоды
weather_data<- data.frame(date=as.Date(a$list$dt_txt,"%Y-%m-%d"),hour=as.character(format(as.POSIXlt(a$list$dt_txt,"%Y-%m-%d %H:%M:%S"),"%H")))

weather<- as.data.table(cbind(weather_data,a$city$id,weather_main,weather_weather,weather_clouds,weather_wind,weather_rain,weather_snow,weather_sys))
weather$pod <- as.factor(weather$pod)
weather$main <- as.factor(weather$main)
weather$description <- as.factor(weather$description)
weather$icon <- as.factor(weather$icon)
names(weather) <- gsub("^id","weather_id",names(weather))
names(weather)[3] <- "city_id"
str(weather)
rm(list = ls()[ls()!="weather"])
weather$hour <- as.numeric(as.character(weather$hour))
weather2<- copy(weather)
weather2[,hour:=hour+1]
weather3<- copy(weather)
weather3[,hour:=hour+2]
weather
weather2
weather3
weather4<- rbind(weather,weather2,weather3)
weather4<- weather4[order(date,hour)]
weather<- copy(weather4)
rm(list = ls()[ls()!="weather"])
names(weather)<- gsub("^all","alll",names(weather))
weather


drv <- JDBC("com.mysql.jdbc.Driver",
            "C:/Users/user/Documents/Downloads/sqldeveloper/jdbc/lib/mysql-connector-java-3.1.14/mysql-connector-java-3.1.14-bin.jar", "`")

con <- dbConnect(drv,"jdbc:mysql://185.220.32.98:3306/energo","alex", "ksf8DL347#dkfj45*")

# Презапись таблицы 
# dbWriteTable(con,"weather",weather)
# dbWriteTable(con,"weather",all_city_id)

weather$date<- as.character(weather$date)
weather$pod<- as.character(weather$pod)
weather$main<- as.character(weather$main)
weather$description<- as.character(weather$description)
weather$icon<- as.character(weather$icon)
weather$date_zaliva <- as.character(Sys.Date())

for(i in 1:nrow(weather)){
  req <- paste("INSERT INTO weather (date, hour, city_id,temp,temp_min, temp_max, pressure, sea_level,
grnd_level, humidity, temp_kf,weather_id, main, description, icon, alll, speed, deg, rain,snow,pod,date_zaliva
  ) VALUES
               ('",weather[i,1],"',",weather[i,2],",",weather[i,3],",",weather[i,4],",",weather[i,5],","
               ,weather[i,6],",",weather[i,7],",",weather[i,8],",",weather[i,9],",",weather[i,10],","
               ,weather[i,11],",",weather[i,12],",'",weather[i,13],"','",weather[i,14],"','",weather[i,15],"',"
               ,weather[i,16],",",weather[i,17],",",weather[i,18],","
               ,ifelse(is.na(weather[i,19]),"NULL",weather[i,19]),","
               ,ifelse(is.na(weather[i,20]),"NULL",weather[i,20]),",'",weather[i,21],"','",weather[i,22],"')"
               ,sep = "")
  # not run, but do to send your query 
  dbSendUpdate(con,req)
  print(i/nrow(weather))
}
dbDisconnect(con)

