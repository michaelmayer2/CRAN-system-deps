# Finding system dependencies on CRAN
# 
# In principle available.packages() can interrogate any CRAN mirror
# By default, a number of fields from the DESCRIPTION file are displayed
# There is an option to extend this and also include SystemRequirements 
# It turns out however that most CRAN mirrors do not include any of the 
# non-default fields of DESCRIPTION in the repository DB (e.g. PACKAGES)
# 
# Package Manager to the rescue: 
#    RSPM maintains all fields in DESCRIPTION
#
# The below code is interrogating RSPM for SystemDependencies 
# and then runs some operations on the data.
# ultimate product is
# 1) a csv file containing packages and their versions with a documented 
#        system dependency
# 2) a csv file with the frequency of each system dependency

# mkdir src
system("mkdir -p src")

# rsync everything
system(paste("rsync --exclude [0-9].[0-9].[0-9]/ --exclude Meta/",
                "--exclude Older/ --exclude */Recommended",
                "--exclude Archive/ --exclude Symlink/ --exclude Old/",
                "-rtlzv --delete",
                "cran.r-project.org::CRAN/src/contrib src"))

# filter out all the symlinks we don't need
system("find src/contrib/ -type l | xargs rm -f")

# write new packages DB with SystemRequirements field
tools::write_PACKAGES(dir="src/contrib",type="source",
                      fields=c("SystemRequirements"))


# Make sure we use local CRAN
r <- getOption("repos")
r["CRAN"] <- paste0("file://",getwd())
r["CRAN"] <- "https://packagemanager.rstudio.com/cran/latest"
options(repos = r)

# get data frame of everything 

data<-as.data.frame(available.packages(fields=c("SystemRequirements")))

systemdeps<-unique(data$SystemRequirements)

library(dplyr)

currdate=format(Sys.time(), "%Y-%m-%d")

# file with package, version and system dependency
write.csv(na.omit(data %>% 
                    select(Version,SystemRequirements)),
          file=paste0("system-deps-",currdate,".csv"))

# file with system dependency and number of occurrence of dependency
write.csv(na.omit(data %>% 
                    group_by(SystemRequirements) %>% 
                    summarize(count=n())),
          file=paste0("system-deps-freq-",currdate,".csv"))
