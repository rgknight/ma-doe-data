# Calculate the number of students enrolled in Boston by Grade

require(dplyr)
require(tidyr)
require(stringr)
options(stringsAsFactors=F)

setwd('C:/Users/rknight/Documents/GitHub/ma-doe-data')

# School Files

cleanup <- function(thisone){
  ifiles <- list.files(path= "data/enrollmentbygrade", pattern=paste(thisone))
  
  all <- NULL
  
  for (file in ifiles) {
    print(file)
    raw <- read.csv(paste('data/enrollmentbygrade/', file, sep = '/'))
    parts <- strsplit(file, " ")
    year <- parts[[1]][3]
    year <-substr(year, 1, nchar(year)-4) #remove the last 4 char (.csv)
    raw$year <- year
    
    # There are two sets of columns
    if ('UG' %in% names(raw)) {
      raw <- mutate(raw, SP = NA)
    }  else {
      raw <- mutate(raw, UG = NA, X13 = NA, X14 = NA)
    }
    all <- rbind(all, raw)
  }
  
  names(all) <- tolower(names(all))
  
  if ("school" %in% names(all)) {
    tmp <- rename(all, name = school)
  }
  else{
    tmp <- rename(all, name = district)
  }

  long <- tmp %>%
    gather(measure, students, -name, -org.code, -year) %>%
    mutate(grade = extract_numeric(measure),
           grade = ifelse(measure == "k", 0,
                            ifelse(measure == 'pk', -1, grade))) 

 
 long %>%
     select(-measure) %>%
     filter(extract_numeric(students) > 0) %>%
     group_by(name) %>%
     mutate(maxgrade = max(grade))
  
}

district <- cleanup("district")
schools <- cleanup("school")

# Go get location information for schools
locations <- read.csv('data/school addresses.csv')
closed.charter <- read.csv('data/closed charter school addresses.csv')
zips <- read.csv('data/boston zip codes.csv')

locations <- rbind(locations, closed.charter %>% select(-school) )

locations$zip <- as.numeric(str_sub(locations$address, -5))

locations$boston <- locations$zip %in% zips$zip

locations <- locations %>% rename(org.code = orgcode)

long.loc <- left_join(schools, locations)

long.loc$charter <- grepl("charter", tolower(long.loc$name))
long.loc$charter.alt <- grepl("cs$", tolower(long.loc$name))

long.loc$charter <- ifelse(long.loc$charter.alt==TRUE, TRUE, long.loc$charter)

need.addy <- unique(long.loc %>% 
                    filter(charter==TRUE, is.na(boston)) %>% 
                    select(org.code, name))

write.csv(need.addy, "data/Charter need address.csv", na="", row.names = F)

bos.charter.enroll <- long.loc %>%
  filter(charter==TRUE, boston == TRUE) %>%
  group_by(year, grade) %>%
  summarise(students = sum(extract_numeric(students), na.rm = T),
            name = "Boston Charters",
            org.code = 999,
            maxgrade = NA)

boston.enroll <- rbind(district %>% filter(org.code==350000), bos.charter.enroll)

boston.enroll$name <- with(boston.enroll, ifelse(org.code ==350000 , "District School", name))

write.csv(boston.enroll, "data/Total Boston Enrollment.csv", na="", row.names = F)

