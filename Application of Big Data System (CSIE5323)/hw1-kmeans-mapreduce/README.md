# K-Means Clustering with MapReduce

This project demonstrates the implementation of the K-means clustering algorithm using the MapReduce programming model in Python. The goal is to simulate distributed computing by processing data across multiple processes.

## Table of Contents

- [Overview](#overview)
- [Requirements](#requirements)
- [File Structure](#file-structure)
- [TODO](#todo)
- [How to Run](#how-to-run)
- [Submission](#submission)

## Overview

K-means clustering is an unsupervised learning algorithm used to partition a dataset into `k` distinct clusters based on feature similarity. In this implementation, we use the MapReduce paradigm to parallelize the clustering process.

## Requirements

- Python 3.x
- NumPy library
- Multiprocessing library (included with Python)

## File Structure

```
kmeans_mapreduce/
│── README.md
│── main.py
│── mapper.py
│── reducer.py
│── data.txt
```

## TODO

Complete `run()` in mapper.py and reducer.py.

## How to Run

Run K-Means Clustering: Execute the main.py script to start the K-means clustering process.

```
python main.py
```

## Submission

Rename the folder to `hw1_{student_id}` format, for example `hw1_r12345678`, and zip it. Your folder should contain mapper.py and reducer.py only. **If the submission does not follow the specified format, it will be graded as zero.**

```
hw1_r12345678/
│── mapper.py
│── reducer.py
```
