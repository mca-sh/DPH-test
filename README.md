# DPH-test

## Goals

The goals of DPH test are:
1. To assess the use of **discrete phase-type distributions (DPH)** to model in single molecule **kinetic heterogeneity** in ensemble dwell time histogram
2. To assess the accuracy of the **HMM maximum likelihood estimator** (*i.e.*, without further model selection) given by the Baum-Welch algorithm apllied to single molecule **states sequences** (*i.e.*, with a 0-1 binary event matrix)

Both methods are part of the analysis workflow of [MASH-FRET](https://github.com/RNA-FRETools/MASH-FRET)'s Transition analysis module.

## Method

To address these problems, single molecule state sequences will be simulated with different state degeneracies (goal 1) and for all different transition paths allowed for each state configuration (goal 2).

Simulated state sequences will be analyzed in MASH-FRET and the analysis output, in terms of number of degenerated states and transition paths, will be compared to the simulation ground truth to evaluate goals 1 and 2.

## Content

DPH-test contains all the scripts used to:
* **Simulate 2-state synthetic data sets** (calling MASH-FRET's Simulation module) with state degeneracies 1-1, 1-2, 1-3 and 2-2 and for all possible transition paths (2, 13, 150 and 150 paths)
* **Analyze simulated data** (calling MASH-FRET's Transition analysis module): For each simulated data set: (1) determines state degeneracies by training discrete phase-type (DPH) distributions of complexities 1 to 4 and selecting DPHs that minimize the BIC and, (2) optimizes ensemble HMM on states sequences with the Baum-Welch algorithm. This took 5 days to complete with an i7 CPU (2.20GHz) and 8GB of RAM.
* **Evaluate and summarize analysis performances** by comparing state degeneracies and HMM parameters to the simulated ground truth

<img src="DPH-test_perf-summary.png">
