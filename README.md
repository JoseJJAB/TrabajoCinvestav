# Codigo en Julia para deteccion de Spiklets

This package shall cointain code for helping spiklet detection and 
clasification via automated criteria. The code is usefull in the
analysis of Axon Binary Files type 1 and 2, cointaining
the record of Current and Voltage Clamp techniques applied to
neurons. Other formats of the data may be analysed, such as hdf5
 or brw (Brainwave hdf5 compatible) files. 
 
 The automated detection is based on the identification of
 characteristics of the
 of the temporal derivative of the signal. This provides stable and 
 usefull interpretable criteria for the identification of
 a putative spike or spikelet.
 
 The code is written mostly in Julia. We make extensive use of
 PyABF, a Python module for opening and reading abf files,
 through PyCall. Graphics are made via PyPlot. 
 
 Our code shall be public with GNU Public Licence 3. 
 
 
 (c) 2019
 Coding, tests and mathematical work by W.P. Karel Zapfe Zaldivar.
 Physiological and electroneurological work by Jose Jesus Aceves.
 
 


