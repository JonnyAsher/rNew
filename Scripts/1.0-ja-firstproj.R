## Created by Eduardo Maia
## thedatagame.com.au
## Twitter: @thedatagame
install.packages('ggplot2')
install.packages('grid')
install.packages('gridExtra')
install.packages('png')
install.packages('jpeg')
install.packages('RCurl')
install.packages('hexbin')
install.packages('plyr')
# load all packages to be used
library(rjson)
library(ggplot2)
library(grid)
library(gridExtra)
library(png)
library(jpeg)
library(RCurl)
library(hexbin)
library(plyr)

# shot data for Stephen Curry
playerID <- 201939
shotURL <- paste("http://stats.nba.com/stats/shotchartdetail?CFID=33&CFPARAMS=2014-15&ContextFilter=&ContextMeasure=FGA&DateFrom=&DateTo=&PlayerPosition=&GameID=&GameSegment=&LastNGames=0&LeagueID=00&Location=&MeasureType=Base&Month=0&OpponentTeamID=0&Outcome=&PaceAdjust=N&PerMode=PerGame&Period=0&PlayerID=",playerID,"&PlusMinus=N&Position=&Rank=N&RookieYear=&Season=2014-15&SeasonSegment=&SeasonType=Regular+Season&TeamID=0&VsConference=&VsDivision=&mode=Advanced&showDetails=0&showShots=1&showZones=0", sep = "")

# import from JSON
shotData <- fromJSON(file = shotURL, method="C")

# unlist shot data, save into a data frame
shotDataf <- data.frame(matrix(unlist(shotData$resultSets[[1]][[3]]), ncol=24, byrow = TRUE))

# shot data headers
colnames(shotDataf) <- shotData$resultSets[[1]][[2]]

# covert x and y coordinates into numeric
shotDataf$LOC_X <- as.numeric(as.character(shotDataf$LOC_X))
shotDataf$LOC_Y <- as.numeric(as.character(shotDataf$LOC_Y))
shotDataf$SHOT_DISTANCE <- as.numeric(as.character(shotDataf$SHOT_DISTANCE))

# have a look at the data
View(shotDataf)


## start plots
# simple plot using EVENT_TYPE to colour the dots
ggplot(shotDataf, aes(x=LOC_X, y=LOC_Y)) +
  geom_point(aes(colour = EVENT_TYPE))



# half court image
courtImg.URL <- "https://thedatagame.files.wordpress.com/2016/03/nba_court.jpg"
court <- rasterGrob(readJPEG(getURLContent(courtImg.URL)),
                    width=unit(1,"npc"), height=unit(1,"npc"))

# plot using NBA court background and colour by shot zone
ggplot(shotDataf, aes(x=LOC_X, y=LOC_Y)) + 
  annotation_custom(court, -250, 250, -50, 420) +
  geom_point(aes(colour = SHOT_ZONE_BASIC, shape = EVENT_TYPE)) +
  xlim(-250, 250) +
  ylim(-50, 420)



# plot using ggplot and NBA court background image, flip x axis
ggplot(shotDataf, aes(x=LOC_X, y=LOC_Y)) +
  annotation_custom(court, -250, 250, -50, 420) +
  geom_point(aes(colour = SHOT_ZONE_BASIC, shape = EVENT_TYPE)) +
  xlim(250, -250) +
  ylim(-50, 420) +
  geom_rug(alpha = 0.2) +
  coord_fixed() +
  ggtitle(paste("Shot Chart\n", unique(shotDataf$PLAYER_NAME), sep = "")) +
  theme(line = element_blank(),
        axis.title.x = element_blank(),
        axis.title.y = element_blank(),
        axis.text.x = element_blank(),
        axis.text.y = element_blank(),
        legend.title = element_blank(),
        plot.title = element_text(size = 15, lineheight = 0.9, face = "bold"))



# scrape player photo and save as a raster object
playerImg.URL <- paste("http://stats.nba.com/media/players/132x132/",playerID,".png", sep="")
playerImg <- rasterGrob(readPNG(getURLContent(playerImg.URL)), 
                        width=unit(0.15, "npc"), height=unit(0.15, "npc"))

# plot using ggplot and NBA court background
ggplot(shotDataf, aes(x=LOC_X, y=LOC_Y)) + 
  annotation_custom(court, -250, 250, -52, 418) +
  geom_point(aes(colour = EVENT_TYPE, alpha = 0.8), size = 3) +
  scale_color_manual(values = c("#008000", "#FF6347")) +
  guides(alpha = FALSE, size = FALSE) +
  xlim(250, -250) +
  ylim(-52, 418) +
  geom_rug(alpha = 0.2) +
  coord_fixed() +
  ggtitle(paste("Shot Chart\n", unique(shotDataf$PLAYER_NAME), sep = "")) +
  theme(line = element_blank(),
        axis.title.x = element_blank(),
        axis.title.y = element_blank(),
        axis.text.x = element_blank(),
        axis.text.y = element_blank(),
        legend.title = element_blank(),
        plot.title = element_text(size = 17, lineheight = 1.2, face = "bold"))

# add player photo and footnote to the plot
pushViewport(viewport(x = unit(0.9, "npc"), y = unit(0.8, "npc")))
print(grid.draw(playerImg), newpage=FALSE)
grid.text(label = "thedatagame.com.au", just = "centre", vjust = 50)



# plot shots using ggplot, hex bins, NBA court backgroung image.
ggplot(shotDataf, aes(x=LOC_X, y=LOC_Y)) + 
  annotation_custom(court, -250, 250, -52, 418) +
  stat_binhex(bins = 25, colour = "gray", alpha = 0.7) +
  scale_fill_gradientn(colours = c("yellow","orange","red")) +
  guides(alpha = FALSE, size = FALSE) +
  xlim(250, -250) +
  ylim(-52, 418) +
  geom_rug(alpha = 0.2) +
  coord_fixed() +
  ggtitle(paste("Shot Chart\n", unique(shotDataf$PLAYER_NAME), sep = "")) +
  theme(line = element_blank(),
        axis.title.x = element_blank(),
        axis.title.y = element_blank(),
        axis.text.x = element_blank(),
        axis.text.y = element_blank(),
        legend.title = element_blank(),
        plot.title = element_text(size = 17, lineheight = 1.2, face = "bold"))

# add player photo and footnote to the plot
pushViewport(viewport(x = unit(0.9, "npc"), y = unit(0.8, "npc")))
print(grid.draw(playerImg), newpage=FALSE)
grid.text(label = "thedatagame.com.au", just = "centre", vjust = 50)


## zone accuracy plot
# exclude backcourt shots
shotDataS <- shotDataf[which(!shotDataf$SHOT_ZONE_BASIC=='Backcourt'), ]

# summarise shot data
library(plyr)
shotS <- ddply(shotDataS, .(SHOT_ZONE_BASIC), summarize, 
               SHOTS_ATTEMPTED = length(SHOT_MADE_FLAG),
               SHOTS_MADE = sum(as.numeric(as.character(SHOT_MADE_FLAG))),
               MLOC_X = mean(LOC_X),
               MLOC_Y = mean(LOC_Y))

# calculate shot zone accuracy and add zone accuracy labels
shotS$SHOT_ACCURACY <- (shotS$SHOTS_MADE / shotS$SHOTS_ATTEMPTED)
shotS$SHOT_ACCURACY_LAB <- paste(as.character(round(100 * shotS$SHOT_ACCURACY, 1)), "%", sep="")

# plot shot accuracy per zone
ggplot(shotS, aes(x=MLOC_X, y=MLOC_Y)) + 
  annotation_custom(court, -250, 250, -52, 418) +
  geom_point(aes(colour = SHOT_ZONE_BASIC, size = SHOT_ACCURACY, alpha = 0.8), size = 8) +
  geom_text(aes(colour = SHOT_ZONE_BASIC, label = SHOT_ACCURACY_LAB), vjust = -1.2, size = 8) +
  guides(alpha = FALSE, size = FALSE) +
  xlim(250, -250) +
  ylim(-52, 418) +
  coord_fixed() +
  ggtitle(paste("Shot Accuracy\n", unique(shotDataf$PLAYER_NAME), sep = "")) +
  theme(line = element_blank(),
        axis.title.x = element_blank(),
        axis.title.y = element_blank(),
        axis.text.x = element_blank(),
        axis.text.y = element_blank(),
        legend.title = element_blank(),
        legend.text=element_text(size = 12),
        plot.title = element_text(size = 17, lineheight = 1.2, face = "bold"))

# add player photo and footnote to the plot
pushViewport(viewport(x = unit(0.9, "npc"), y = unit(0.8, "npc")))
print(grid.draw(playerImg), newpage=FALSE)
grid.text(label = "thedatagame.com.au", just = "centre", vjust = 50)
© 2017 GitHub, Inc.
Terms
Privacy
Security
Status
Help
Contact GitHub
API
Training
Shop
Blog
About