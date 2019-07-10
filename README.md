# FiloQuant
Filopodia quantification plugin

FiloQuant is a user friendly and modifiable tool for automated detection and quantification of filopodia properties such as length and density. 
We developed FiloQuant as a plugin for the freely available, and popular, ImageJ with inter operating systems compatibility. 

FiloQuant was designed with four goals in mind: 

First, we aimed to make this software as easy to use as possible. To this end we created versions of FiloQuant containing step-by-step user validation of the various processing stages to help users to achieve optimal settings for filopodia detection.

Second, this software was designed to simplify and speed up the analysis of filopodia properties. To this endsemi-automated as well as a fully-automated versions of FiloQuant are provided. Using the semi-automatedversion of FiloQuant, users can analyze rapidly a large number of images while keeping control over the settings used to analyze each image and modify these settings on the fly to improve the accuracy of detection.

Using the automated version of FiloQuant, users can choose the settings for analyzing a largenumber of images at once (batch analysis). This latter version of FiloQuant is especially useful for screeningpurposes or to analyse filopodia properties and dynamics from live-cell imaging data. Results can then be compiled using the R script provided.

Third, we aimed to make FiloQuant as broadly usable/flexible as possible, with no limitation in terms of cell geometry or imaging modality. We successfully used FiloQuant with images (acquired on differentmicroscopes) of cells migrating collectively or as single cells in various environments including 2D fibronectin and 3D cell-derived matrices. In addition, we tested the ability of FiloQuant to detect filopodia inneurons, which have a more complex morphology. 

Finally, although this software was found to effectively identify filopodia in many different types of images, we appreciate that others might require extra functionalities or the ability to included FiloQuant within larger analysis routines. To facilitate easy modification of FiloQuant, we wrote this software using the ImageJ macro language that we also fully annotated, which can therefore be edited with limited coding knowledge.
