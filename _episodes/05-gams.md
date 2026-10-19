---
title: Spatial and Temporal Modelling with GAMs
teaching: 80
exercises: 0
questions:
  - What are GAMs?
  - Why are GAMs a useful tool for modelling animal movements?
  - How do I make a GAM in R? 
---

GAM is short for 'Generalized Additive Model', a type of statistical model. 

This hands-on coding workshop will walk through the basics of spatiotemporal modelling with Generalized Additive Models (GAMs) using the *mgcv* package in R. 

GAMs offer functions that allow some control for spatial and temporal autocorrelation, flexibility for data that may have multiple inflection points, and have been widely applied to ecological data in the literature. Attendees will use a real acoustic telemetry dataset to model the relationship of animal detections with space and time, evaluate their model, and use it to predict spatial patterns in animal movements.

## Background on GAMs

This workshop will begin with a presentation - see [the slide deck here](https://docs.google.com/presentation/d/13S-oN1ISKv1PZpZL_Gr4ciPz4ili1mzFjsq109hS4m8/edit?usp=sharing)



## Setup
~~~
## ---- Install ----

library(mgcv)
library(gratia)
library(tidyverse)

# Load dataset for blue sharks
nsbs_matched_2021 <- read_csv("nsbs_matched_detections_2021.zip") #Import 2021 detections
nsbs_matched_2022 <- read_csv("nsbs_matched_detections_2022.zip") # Import 2022 detections
nsbs_matched_full <- rbind(nsbs_matched_2021, nsbs_matched_2022) #Now join the two dataframes

# remove release records for modelling
nsbs_matched_full <- nsbs_matched_full %>% 
  filter(receiver != 'release') 
~~~
{: .language-r}


## Data Exploration

One of the first steps to making model is understanding your dataset. In this example we will look at the tag sensor records and determine if there are any that might be interesting to explore.

On your own dataset you'd want to do a much deeper dive into the dataset, making maps, plots, and summaries.

~~~
## ---- Data Exploration ----

#What sensors do we have?
nsbs_matched_full %>% 
  group_by(sensorType) %>%  
  summarize(count=n()) 
# Pressure and Temperature values exist

nsbs_matched_full %>% 
  filter(sensorType == 'pressure') %>% 
  ggplot(aes(dateCollectedUTC, sensorValue, colour = detectedBy))+
  scale_y_reverse() +
  geom_point() +
  facet_wrap(~catalogNumber)
# a few animals have Pressure values.
~~~
{: .language-r}


## Research Question

Models are useful tools to explain relationships, make predictions, and test hypotheses. But they are most useful when they are designed specifically to answer a biological question. Including every covariate and "seeing what is significant" can lead to erroneous results. It's important to forumlate your models based on biological questions.

As they say.... "all models are wrong, but some are useful".

#### Research question: how does Depth vary across time?  

## Data Prep

Now that we have our research question, we can format our dataset so that we can feed it into our model. This includes some important formatting:
- "animal ID" (called catalogNumber in our dataset) needs to be formatted as a *factor* to use as a random effect
- our sensor data should be subsampled to one sample per hour (per individual) to reduce temporal autocorrelation

~~~
## ---- Data Prep ----

# take the first Pressure reading per hour per day for each individual 
# to decrease temporal autocorrelation

model_data <- nsbs_matched_full %>% 
  filter(sensorType == 'pressure') %>% 
  filter(sensorValue >= 0) %>%  #filter out bad records
  group_by(catalogNumber, hour_floor = floor_date(dateCollectedUTC, "hour")) %>% 
  filter(dateCollectedUTC == min(dateCollectedUTC)) %>% 
  select(catalogNumber, station, dateCollectedUTC, hour_floor,
         sensorType, sensorValue) %>% 
  ungroup() %>% 
  # need individual ID as a factor in order to use as a random effect
  # may need columns for other time bins to try different models
  mutate(fcatnum = as.factor(catalogNumber), 
         day = yday(hour_floor),
         week=week(hour_floor))

names(model_data)
~~~
{: .language-r}


## Model Building
Now we can begin to make a model. In the next several sections we will make multiple models to compare different model formulations, and learn about building and coding GAMs piece-by-piece.


### Comparing Smoothers

A smooth is what makes predictions between points make sense, but there are multiple types.
~~~
### Comparing different smoothers ----

# a smooth is what makes predictions between points make sense

#circular
a <-model_data %>% 
  mutate(h=hour(dateCollectedUTC)) %>% 
  bam(sensorValue ~ s(h, bs="cc", k=5),  #circular spline for hour
      data=., 
      method="fREML", 
      discrete=T)

#thin plate (default)
b <-model_data %>% 
  mutate(h=hour(dateCollectedUTC)) %>% 
  bam(sensorValue ~ s(h, bs="tp", k=5),  #thin plate spline for hour
      data=.,  
      method="fREML", 
      discrete=T)

# compare the two models

# set a theme for ourselves to use in our plots
theme_set<-theme_classic()+
  theme(text=element_text(size=20), axis.text=element_text(colour="black"))+
  theme(legend.position="top") 

# plot the predictions from the different smoothers

tibble(h=c(0:23)) %>% 
  mutate(circular=predict.gam(a, newdata=.)) %>% 
  mutate(thin_plate=predict.gam(b, newdata=.)) %>% 
  gather(key, value, -h) %>% 
  ggplot(aes(h, value, colour=key))+
  geom_line(linewidth=2)+
  theme_set +
  labs(x="Hour", y="Predicted Depth", colour="Model")+
  scale_y_reverse(limits=c(50, 0))+
  geom_hline(yintercept=0)+
  coord_polar()

# here you can see that the circular smooth was able to predict time more accurately,
# where hour 23 and hour 0 needed to have similar values
~~~
{: .language-r}


### Adding Random Effects

Next we can add a random effect of individual to account for individual variation. This is only possible if individual ID is a FACTOR. We did this already in the data prep step so we are ready!

We're also going to test two different functions to make a GAM --> `mgcv::gam` and `mgcv::bam`

~~~
### Adding random effects ----

# use GAM first

m1 <-model_data %>% 
  mutate(h=hour(dateCollectedUTC)) %>% 
  gam(sensorValue ~ 
        s(h, bs = "cc", k=5)+ 
        s(fcatnum, bs="re"), #random effect of individual!
      data=., 
      method="REML")

#use BAM next to compare

m2 <-model_data %>% 
  mutate(h=hour(dateCollectedUTC)) %>% 
  bam(sensorValue ~ 
        s(h, bs = "cc", k=5)+ 
        s(fcatnum, bs="re"), #random effect of individual!
      data=., 
      method="fREML", 
      discrete=T)

# predict depth use for one individual to compare GAM and BAM

tibble(h=c(0:23)) %>% 
  mutate(fcatnum='NSBS-Lindsay') %>% 
  mutate(gam=predict.gam(m1, newdata=., type="response", exclude=c("s(fcatnum)"))) %>% 
  mutate(bam=predict.gam(m2, newdata=., type="response", exclude=c("s(fcatnum)"))) %>%
  mutate(i=gam-bam) %>% 
  gather(key, value, -h, -fcatnum, -i) %>% 
  ggplot(aes(h, value, colour=i))+
  geom_line(size=2)+
  theme_set+
  facet_wrap(~key)+
  labs(x="Hour", y="Predicted depth", colour="Difference between predictions")+
  theme(legend.key.width=unit(3, "cm"))

# GAM and BAM are super similar! the same output
~~~
{: .language-r}


### Learning about Knots
How "wiggly" should our data be? How many inflection points do we expect? How do we keep the predictive power without overfitting? Arguably the most important part of formulating your GAM will be setting the knots in the function.

~~~
### Playing with different knots ----

# try 5 "wiggles"
k1<-model_data %>% 
  mutate(h=hour(dateCollectedUTC)) %>% 
  bam(sensorValue ~ s(h, bs="cc", k=5), #k value sets the knots
      data=., 
      method="fREML", 
      discrete=T)

# try 15 "wiggles"
k2<-model_data %>% 
  mutate(h=hour(dateCollectedUTC)) %>% 
  bam(sensorValue ~ s(h, bs="cc", k=15), #many more knots
      data=., 
      method="fREML", 
      discrete=T)

#compare the two!
tibble(h=c(0:23)) %>% 
  mutate("k=5"=predict.gam(k1, newdata=., type="response")) %>% 
  mutate("k=15"=predict.gam(k2, newdata=., type="response")) %>% 
  gather(key, value, -h) %>% 
  ggplot(aes(h, value, colour=key))+
  geom_line(size=2)+
  theme_set+
  labs(y="Pressure", x="Hour", colour="model")

#Higher K = more inflection points
~~~
{: .language-r}


### Dealing with Autocorrelation

Tobler's Law: things nearby in space or time are more similar than those further away. This results in autocorrelation: where one measurement is correlated with the next measurement of the same variable. This violates model assumptions of independence.

For temporal autocorrelation, we subset our data already! For spatial autocorrelation we can add in spatial info to the model.

~~~
### Dealing with autocorrelation ----

# temporal autocorrelation - sub-setting
# When we prepped model_data we subset to only include the first pressure per hour (per shark). 
# What if we didn'tt do that?


#new model_data that does NOT subset the time
model_data2 <- nsbs_matched_full %>% 
  filter(sensorType == 'pressure') %>% 
  filter(sensorValue >= 0) %>%  #filter out bad records
  select(catalogNumber, station, dateCollectedUTC, 
         sensorType, sensorValue) %>% 
  ungroup() %>% 
  # need individual ID as a factor in order to use as a random effect
  # may need columns for other time bins to try different models
  mutate(fcatnum = as.factor(catalogNumber), 
         day = yday(dateCollectedUTC),
         week=week(dateCollectedUTC))


# model with subset data
t1<-model_data %>% 
  mutate(h=hour(dateCollectedUTC), yd=yday(dateCollectedUTC)) %>% 
  bam(sensorValue ~ 
        s(h, k=5, bs="cc")+
        s(yd, k=10)+
        s(fcatnum, bs="re"), 
      data=., 
      method="fREML", 
      discrete=T)

# model with NOT subset data
t2<-model_data2 %>% 
  mutate(h=hour(dateCollectedUTC), yd=yday(dateCollectedUTC)) %>% 
  bam(sensorValue ~ 
        s(h, k=5, bs="cc")+
        s(yd, k=10)+
        s(fcatnum, bs="re"), 
      data=., 
      method="fREML", 
      discrete=T)

#compare them
expand_grid(h=c(12),
            yd=c(149:350),
            fcatnum='NSBS-Lindsay') %>% 
  mutate(partial_series=predict.gam(t1, newdata=., type="response", exclude=c("s(fcatnum)"))) %>% 
  mutate(full_series=predict.gam(t2, newdata=., type="response", exclude=c("s(fcatnum)"))) %>% 
  gather(key, value, -h, -fcatnum, -yd) %>% 
  ggplot(aes(yd, value, colour=key))+
  geom_point(data=nsbs_matched_full %>% 
               mutate(h=hour(dateCollectedUTC), yd=yday(dateCollectedUTC), fcatnum=factor(catalogNumber)),
             aes(yday(dateCollectedUTC), sensorValue), inherit.aes=F)+
  geom_path(size=2)+
  theme_set+
  labs(x="Date", y="Pressure", colour="Model")


# spatial autocorrelation - add in spatial terms

# we need to have lat/long in our model data
# let's add it back into the dataset
model_data3 <- nsbs_matched_full %>% 
  filter(sensorType == 'pressure') %>% 
  filter(sensorValue >= 0) %>%  #filter out bad records
  group_by(catalogNumber, hour_floor = floor_date(dateCollectedUTC, "hour")) %>% 
  filter(dateCollectedUTC == min(dateCollectedUTC)) %>% 
  select(catalogNumber, station, dateCollectedUTC, hour_floor,
         sensorType, sensorValue, decimalLatitude, decimalLongitude) %>% 
  ungroup() %>% 
  # need individual ID as a factor in order to use as a random effect
  # may need columns for other time bins to try different models
  mutate(fcatnum = as.factor(catalogNumber), 
         day = yday(hour_floor),
         week=week(hour_floor))

names(model_data3)

#spatial model
s1 <- model_data3 %>% 
  mutate(h=hour(dateCollectedUTC), yd=yday(dateCollectedUTC)) %>% 
  bam(sensorValue ~ 
        s(h, k=5, bs="cc")+
        s(yd, k=10)+
        s(decimalLongitude,decimalLatitude, k = 15)+ #adding in your spatial term, just like this!
        s(fcatnum, bs="re"), 
      data=., 
      method="fREML", 
      discrete=T)
#even if adding in the spatial terms isn't part of your hypothesis testing
#it will always be more correct to avoid assumption violations.
#animal behaviour will nearly always be influenced by space in some way.

~~~
{: .language-r}



### Interactions and Families

What if you want to know how the hourly depth-use changes through the year? An interaction between hour-of-day and day-of-year can do this! Many animals change their diel patterns across the year.

Adding in regression family is also important so impossible values aren't predicted. For example: pressure should never be negative, therefore predictions shouldn't be "normal/Gaussian".

~~~
### Adding in interactions and family ----

i1 <- model_data %>% 
  mutate(h=hour(dateCollectedUTC), yd=yday(dateCollectedUTC)) %>% 
  bam(sensorValue ~ 
        te(h, yd, bs=c("cc", "tp"), k=c(5, 10))+ #interaction between hour and day
        s(fcatnum, bs="re"), 
      data=., 
      family=Gamma(link="log"), #family is based on response variable type
      method="fREML", 
      discrete=T)

#lets see if hourly depth is predicted to change over the year!
expand_grid(h=c(0:23), yd=c(149:350)) %>% 
  mutate(fcatnum='NSBS-Lindsay') %>% 
  mutate(value=predict.gam(i1, newdata=., type="response", exclude=c("s(fcatnum)"))) %>% 
  #mutate(i="Simple model, AIC=426 801") %>% 
  ggplot(aes(yd, h, fill=value))+
  geom_raster()+
  scale_fill_viridis_c()+
  theme_set+
  theme(legend.key.width=unit(3, "cm"))+
  labs(x="Date", y="Hour", fill="Predicted pressure")
#hmmm no signal here for the sharks
#we might not have enough data!
~~~
{: .language-r}


## Model Checking

After creating your model, there are different ways to check it. Most importantly - it needs to be biologically relevant. Generally, you are comparing the "fit" of predictions to observed data, and checking out the residuals to understand what isn't being captured.

~~~
## Model checking ----

# compare model i1 (random effects, interactions, family added) 
# with model a (very simple)

AIC(a,i1)

# the gratia package has some great diagnostic plots

# things to look for:
# QQ plot should have a straight line
# Histogram of residuals should be normal around 0
# Observed vs fitted should be along a 1:1 line
# Residuals vs linear predictor should not have observable patterns

#gam.check(i1) #fine but not great
appraise(i1) #assessment plots/QQ/etc. Really good!
appraise(a)

draw(i1) #partial effects plots - start picking out effects patterns!
draw(a)

summary(i1)

# looking at the residuals can also help understand how your model is performing
# In a well-fitted model, residuals should be normally distributed around 0. 

hist(resid(i1))
acf(resid(i1))

hist(resid(a))
acf(resid(a))

#in summary - i1 is better than a!
#but this model still kinda sucks - missing an important term for sure!

~~~
{: .language-r}


## Supplemental Notes

We didn't have enough time to go through everything in this workshop. Here's some more thoughts:


### Spatial Predictions Mapping

~~~
## Supplemental notes ----

# out of scope for this workshop, but with s1 (spatial data) you can 
# plot your predictions onto a shapefile!

# example workflow:

#- first use expand_grid: to make a df with all lat/longs, and dates, for your dataset
#     - NOTE: ensure lat/lon are in easting and northing so they make a perfect grid
#- predict.gam: across your new df (examples above using predict.gam)
#- turn predictions into geometry (st_as_sf or something similar!)
#- cut out predictions that are on land (st_intersect with your water shapefile)
#- plot your basemap (land and water) PLUS your predictions (coloured by value) to make a heatmap of some kind

# example heatmap code:

#ggplot()+
#  geom_sf(data = WATER_SHAPEFILE) + #water outline
#  geom_sf(data = predicted_values_df, #predictions within the water
#          aes(utm_easting, utm_northing, col = value)) +
#  scale_colour_viridis_c(option = 'turbo') +
#  facet_wrap(~yd) 
~~~
{: .language-r}


### Notes about Count Models

~~~
## Notes about count models ----

# Should add absences into the model to improve.
# So a dataset with "number of individuals detected at each receiver, each week" would need
# 0s added for weeks/receivers where no individuals were detected.
# Then use GAM to predict count between receivers. Turn it into a heatmap!

# To account for loss of individuals as the study progresses, you
# can add an offset for the # of “active tags” so the count would be a proportion (# detected/ # that COULD have been detected)

# To understand seasonal distribution you can use a 3-way interactions between space and time
# it can be coded like:

#weeky_indiv_count ~  
#  te(utm_easting, utm_northing, week, 
#     d = c(2,1), # dimensions - a lat/lon smooth (2 dimensions) through time (1 dimension), rather than a full 3-way interaction between lat/lon/week. 
#     k=c(50, 15), # k for space, k for time. for lat/long: this is actually sqrt(50), so actually 7 knots each
#     bs=c('tp','cc')), 
#knots=list(week=c(0.5, 53.5)), #specifying that knots for week should overlap (my df had 53 weeks)
#data =.,
#family = 'nb',
#method = 'fREML',
#discrete = T)
~~~
{: .language-r}