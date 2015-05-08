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
locations <- read.csv('data/address-source/school addresses.csv')
closed.charter <- read.csv('data/address-source/closed charter school addresses.csv')
closed.bps <- read.csv('data/address-source/closed BPS school addresses.csv')
zips <- read.csv('data/address-source//boston zip codes.csv')

locations <- rbind(locations, closed.charter %>% select(-school), closed.bps %>% select(-school) )

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

write.csv(need.addy, "data/address-source/Charter need address.csv", na="", row.names = F)

long.loc$boston2 <- grepl("^boston", tolower(long.loc$name))

need.addy <- unique(long.loc %>% 
                      filter(charter==FALSE, is.na(boston), boston2 == TRUE) %>% 
                      select(org.code, name))

write.csv(need.addy, "data/address-source/BPS need address.csv", na="", row.names = F)


bos.charter.enroll <- long.loc %>%
  filter(charter==TRUE, boston == TRUE) %>%
  group_by(year, grade) %>%
  summarise(students = sum(extract_numeric(students), na.rm = T),
            name = "Boston Charters",
            org.code = 999,
            maxgrade = NA)

boston.enroll <- rbind(district %>% filter(org.code==350000), bos.charter.enroll)

boston.enroll$name <- with(boston.enroll, ifelse(org.code ==350000 , "District School", name))

write.csv(boston.enroll, "data/enroll-output/Total Boston Enrollment.csv", na="", row.names = F)

write.csv(long.loc %>% filter(boston == TRUE), "data/enroll-output/Boston School Enrollment with Location.csv", na="", row.names = F)

# Goal: Round lat/long, take the average in an area
latlong <- long.loc %>%
  filter(year %in% c(2005, 2010, 2015), !is.na(grade), boston == TRUE) %>%
  select(org.code, year, students, grade, latitude, longitude, zip, address, charter, name) %>%
  mutate( latitude = str_sub(as.character(latitude), 1, 6),
          longitude = str_sub(as.character(longitude), 1, 7),
          latlong = paste(as.character(latitude), as.character(longitude)))

latlong2 <- latlong %>%
  group_by(year, grade, latlong) %>%
  summarise(students = sum(extract_numeric(students), na.rm = T) ,
            longitude = max(longitude), 
            latitude = max(latitude))

latlong2 <- latlong2 %>%
  mutate(students = ifelse(is.na(students), 0, students)) %>%
  spread(year, students, fill = 0) %>%
  mutate(stu_2015_2010 = `2015` - `2010`,
         stu_2015_2005 = `2015` - `2005`,
         stu_2015_2010_abs = abs(stu_2015_2010),
         stu_2015_2005_abs = abs(stu_2015_2005))

join_names <- latlong %>% select(latlong, name, address)
join_names <- distinct(join_names)
join_names <- join_names %>% 
  group_by(latlong) %>% 
  summarise(name = last(name),
            address = last(address))

latlong3 <- left_join(latlong2, join_names)

write.csv(latlong3, "data/enroll-output/Boston Enrollment Wide.csv", row.names = F, na = "0")

# Figure out grade level configurations
gl <- long.loc %>%
  filter(boston == TRUE, !is.na(grade), students > 0) %>%
  group_by(org.code, year) %>%
  mutate(maxgrade = max(grade),
         mingrade = min(grade))

write.csv(gl, "data/enroll-output/Boston Enrollment by School Type.csv", row.names = F, na = "0")
