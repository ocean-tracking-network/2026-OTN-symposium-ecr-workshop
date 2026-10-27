---
title: Leveraging Yet Another Positioning Solver (YAPS)
exercises: 90
questions:
  - How can I use YAPS in conjunction with other movement analyses?
  - What interpretable results are possible when combining YAPS, HMMs, and iSSFs? 
---
Welcome to our Acoustic Telemetry Pipeline workshop! The goal of this workshop is to familiarize participants with the concept of Yet Another Positioning Solver (YAPS), Hidden Markov Models (HMMs), and Integrated Step Selection Functions (iSSFs) while providing a workflow that participants can use to turn raw telemetry data into preliminary results. 


**Please see the workshop website here for code and other details:** [https://jonrodemann.github.io/OTN_iSSF_Workshop_2026/](https://jonrodemann.github.io/OTN_iSSF_Workshop_2026/)


We will start the workshop by providing background, theory, and case studies on YAPS, HMMs, and iSSFs. We will then walk through the pipeline from raw data to results using R code. R scripts and data are provided to encourage participants to follow along and use this pipeline on their own acoustic data.

This workshop provides an example of a workflow for positional acoustic telemetry data. These data are collected in a receiver array that is set up so that pings from tags can be heard by more than one receiver. While manufacturers provide their own algorithms to solve for these positions, they are either solved by proprietary software or paid services that lack transparency. The YAPS algorithm was created to provide a transparent algorithm to solve for acoustic telemetry positions. Using a correlated random walk model trained with signal time of arrival, this algorithm has been shown to be highly accurate and suitable across multiple acoustic telemetry platforms and in many different aquatic environments. 

The analyses we are employing in this workshop are Hidden Markov Models and Integrated Step Selection Functions. HMMs are in a class of models that focus on the decomposition of movement into distinct underlying states. The time series that is input into the HMM consists of regular time interval coordinates of an animal's location, which is broken down into step lengths (the Euclidean distance between the locations) and turn angle (the change of direction between the directions of travel). The model then uses these values to assign x number of states using maximum likelihood estimation. The model output includes the average and standard deviation of step length and turn angle for each state found, which can be used on the original data to assign states. 

iSSFs are a type of resource selection function, defined as a function that produces values that are proportional to the probability of use by an animal. These types of models are a popular method to determine and predict relative habitat selection by animals that evaluate the relationships between resource use (i.e., the units of area selected by an animal) and the environmental characteristics associated with each unit of area. iSSFs go one step further by utilizing the movement data to appropriately define resource availability by matching each "used step" with a set of "available steps" randomly sampled from a distribution of characteristics derived from observed steps. The main benefit of using iSSFs over another RSF framework (such as calculating habitat use from known observation points and a background of pseudo-absence points) is that they allow the distinguishing of effects of environmental variables not just on the selection, but the movement process as well.

~~~

~~~
{: .language-r}