
##FOR shCTRLm
##set the working directory for the desired group of files for analysis

library(readr)
library(ggplot2)
library(RColorBrewer) 
library(reshape2) 
library(gridExtra)
library(tools)
library(plyr)
library(matrixStats)
library(tidyverse)


path <- file.choose()
DIR  <- dirname(path)

##call a certain type of file, in this case anything ending with .csv, 
##and populate it into a list called "filename"

filenames <- dir(DIR, full.names=TRUE, pattern =".csv")
filename_short <- file_path_sans_ext(basename(filenames))

##Create a "vector"? named filopodiaCounts and have this hold the number of rows counted
##in each .csv file
##skip = 1 is because the first two rows in each file is 1.header 

##Retrieve filopodia counts
shCTRLmfilopodiaCounts <- sapply(filenames, function(f) nrow(read.csv(f, header = F, skip = 1)))
data.frame(shCTRLmfilopodiaCounts)

# retrieve edge length

EdgeL <- data.frame(nrow = length(filenames), ncol = 2)

for (filename in filenames) {
  
  p = file_path_sans_ext(basename(filename))
  Values <- read_csv(filename) 
  colnames(Values)  <- c("ID","x","y" ,"Length", "edge")
  EdgeL[filename, ] <- sum(Values$edge)
}

EdgeL <- EdgeL[-c(1),] 
colnames(EdgeL)  <- c("Name", "edge")

# Average Filopodia length

AverageLength <- data.frame(nrow = length(filenames), ncol = 2)

for (filename in filenames) {
  
  p = file_path_sans_ext(basename(filename))
  Values <- read_csv(filename) 
  colnames(Values)  <- c("ID","x","y" ,"Length", "edge")
  AverageLength[filename, ] <- mean(Values$Length)
}

AverageLength <- AverageLength[-c(1),] 
colnames(AverageLength)  <- c("x", "y")


Results <- data.frame(filename_short, shCTRLmfilopodiaCounts,EdgeL$edge, AverageLength$x)
colnames(Results)  <- c("filename","Filopodia_count", "EdgeL", "Average_Length")   

# Rename the result table
##the other paralog filopodia counts also
write.csv(Results, file=paste(DIR, "_Results.csv", sep=""), row.names = T)

