# iraklis7_scg

## Description
The Specification Compliance Generator uses the GitHub CoPilot Python SDK to identify the delta between two hardware specifications versions of the same technology and produce a detailed report that may be used to further guide the RTL and Verification efforts.

The UART IP Core Specification from OpenCores is used in this project, slightly modifed in order to produce a clear delta for demonstration.

## Project Organization

```
├── LICENSE            <- Open-source license if one is chosen
├── Makefile           <- Makefile with convenience commands
├── README.md          <- The top-level README for developers using 
|                         this project.
├── specs              <- A default specifications repository
├── reports            <- A default repository for the AI generated 
|                         reports.
├── pyproject.toml     <- Project configuration file with package 
|                         metadata for iraklis7_scg and 
|                         configuration for tools like black              
├── requirements.txt   <- The requirements file for reproducing the 
|                         analysis environment
│
├── setup.cfg          <- Configuration file for flake8
│
└── iraklis7_scg       <- Source code for use in this project.
    │
    ├── __init__.py         <-  Makes iraklis7_scg a Python module
    │
    ├── config.py           <-  Store useful variables and
    |                           configuration
    │
    ├── cpw.py              <-  Co-Pilot SDK wrapper class for 
    |                           convenience
    │
    ├── scg.py              <-  The Specification Compliance 
                                Generator class
    
```

--------

## Installation 
The project may be downladed though PyPi, using the following commands:\
pip install iraklis7_scg\
pip install -r requirements.txt