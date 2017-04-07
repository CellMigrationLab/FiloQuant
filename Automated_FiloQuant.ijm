//=============================================================================================//
//																																																							
// ImageJ macro which measure filopodia density and length. 																																
// Batch processing version of the macro																																		
// This macro requires Enhanced Local Contrast (CLAHE.class; http://imagej.net/Enhance_Local_Contrast_(CLAHE)), 
//  Skeletonize3D.jar (http://imagej.net/Skeletonize3D), 
//  AnalyzeSkeleton.jar  (http://imagej.net/AnalyzeSkeleton) and Temporal-Color Code (http://imagej.net/Temporal-Color_Code). 															
//																																																						
// Created by Guillaume Jacquemet and Alex Carisey																																					
//																																																							
// Version 1.1 - 27.03.2017																																								
//              																																																	
//=============================================================================================//

// Precautionary measure and variable initialization

requires("1.51a");																				// To maintain general compatibility requirements (i.e. presence of CLAHE)
current_version_script = "v1.1";																// The version number is saved in the log of the expriment
number_of_tif = 0;																				// Initialization of file counter
file_name_index = 0;																			// Initialization of index for storage
number_of_slice = 0;																			// Initialization of file counter
slice_name_index = 0;

// Verify the presence of slave plugins

path_plugins = getDirectory("plugins");
plugin_list = getFileList(path_plugins);
haz_skeletonize = false;
haz_analyzeskeleton = false;
for (i=0;i<plugin_list.length;i++) {
	search_skeletonize = indexOf(plugin_list[i],"Skeletonize3D");
	if (search_skeletonize==0) { haz_skeletonize = true; }
	search_analyzeskeleton = indexOf(plugin_list[i],"AnalyzeSkeleton");
	if (search_analyzeskeleton==0) { haz_analyzeskeleton = true; }
}
if(haz_skeletonize == false || haz_analyzeskeleton == false) { exit("Missing plugin!"); }

// Directory structure
	
source_directory = getDirectory("FiloQuant: Choose the directory to analyze");							// Source data loading
results_directory = getDirectory("FiloQuant: Choose the result directory ");							// Path for the results and various outputs
intermediate_results_directory = results_directory+"intermediate files"+File.separator;					// Assemble string for temporary folder


// File listing and counting the number of compatible files available

all_files_list = getFileList(source_directory);															// Create an array with the name of all the elements in the folder
number_files = lengthOf(all_files_list);																// Count the total number of elements in the source folder
for (i=0; i<number_files; i++) {																		// |
	if (endsWith(all_files_list[i], ".tiff") || endsWith(all_files_list[i], ".tif")) {					// |
		number_of_tif = number_of_tif + 1;																// |— Count the number of TIFF/TIF files
	}																									// |
}																										// |
if (number_of_tif == 0) {																				//  ||
	exit("Duh! This folder doesn't contain any compatible files!");										//  ||— Clean exit if no compatible file present in the location
}																										//  ||

// Creating array for full and extensionless filenames
	
file_shortname=newArray(number_of_tif);																				// Array allocation
file_fullname=newArray(number_of_tif);																				// Array allocation
for (i=0; i<number_files; i++) {																					// 
	length_name=lengthOf(all_files_list[i]);																		// 
	if (endsWith(all_files_list[i], ".tiff")) {																		// |
		file_fullname[file_name_index]=all_files_list[i];															// |
		file_shortname[file_name_index]=substring(all_files_list[i],0,length_name-5);								// |— Storage of filename for TIFF file
		file_name_index = file_name_index + 1;																		// |
		}																											// |
	if (endsWith(all_files_list[i], ".tif")) {																		//  ||
		file_fullname[file_name_index]=all_files_list[i];															//  ||
		file_shortname[file_name_index]=substring(all_files_list[i],0,length_name-4);								//  ||— Storage of filename for TIF file
		file_name_index = file_name_index + 1;																		//  ||
	}																												//  ||
}																													// 


		// User can define the settings for the whole analysis

		Dialog.create("FiloQuant batch mode");																			// GUI: create dialog box
		Dialog.addMessage("FiloQuant: Edge detection parameters");														// GUI comment
		Dialog.addNumber("Edge detection: Threshold for cell edges:", 25);												// Input threshold_cell_edges
		Dialog.addNumber("Edge detection: Number of iterations for Open:", 6);											// Input n_iterations_open
		Dialog.addNumber("Edge detection: Number of Cycle for Erode Dilate:", 0);										// Input n_cycles_erode_dilate
		Dialog.addCheckbox("Edge detection: Fill holes on edges?", true);												// Input HoleEdge
		Dialog.addCheckbox("Edge detection: Fill holes?", false);														// Input HoleFill
		Dialog.addMessage("FiloQuant: Filopodia detection parameters");													// GUI comment
		Dialog.addNumber("Filopodia detection: threshold for filopodia:", 25);											// Input for filopodia_threshold
		Dialog.addNumber("Filopodia detection: filopodia minimum size:", 10);											// Input for filopodia_min_size
		Dialog.addNumber("Filopodia detection: filopodia repair cycles:", 0);											// Input for filopodia_repair
		Dialog.addCheckbox("Filopodia detection: Use convolve?", true);												//  Input for use_convolve
		Dialog.addCheckbox("Filopodia detection: use local contrast enhancement?", false); 							//  Input for use_clahe
		Dialog.addNumber("Filopodia detection: maximum distance from the cell edge?", 40);									// Allow user to choose a maximal distance of the filopodia from the edges
		Dialog.addMessage("FiloQuant: Contour measurement parameters");													// GUI comment
		Dialog.addNumber("Contour measurement: number of iterations for Close:", 4);									// Input for Edge_close
		Dialog.addNumber("Contour measurement: number of iterations for Erode:", 2);									// Input for Edge_erode
		Dialog.addNumber("Contour measurement: number of iterations for Dilate:", 2);									// Input for Edge_dilate
		Dialog.addMessage("FiloQuant: Batch mode option");																// GUI comment
		Dialog.addCheckbox("Batch mode: stack analysis?", true); 														// user decide if the folder contain stacks or single images
		Dialog.show();																									// Display GUI
																												
		threshold_cell_edges = Dialog.getNumber();																		// Define threshold_cell_edges
		n_iterations_open = Dialog.getNumber();																			// Define n_iterations_open
		n_cycles_erode_dilate = Dialog.getNumber();																		// Define n_cycles_erode_dilate
		HoleEdge = Dialog.getCheckbox();																				// Define HoleEdge
		HoleFill = Dialog.getCheckbox();																				// Define HoleFill
		filopodia_threshold = Dialog.getNumber();																		// Define filopodia_threshold
		filopodia_min_size = Dialog.getNumber();																		// Define filopodia_min_size
		filopodia_repair = Dialog.getNumber();																			// Define filopodia_repair
		use_convolve = Dialog.getCheckbox();																			// Define use_convolve
		use_clahe = Dialog.getCheckbox();																				// Define filopodia_threshold	
		n_distance_from_edges = Dialog.getNumber();																		// Define Filopodia maximal distance from edge
		Contour_close = Dialog.getNumber();																				// Define Edge_close
		Contour_erode = Dialog.getNumber();																				// Define Edge_erode
		Contour_dilate = Dialog.getNumber();																			// Define Edge_dilate
		Stack_analysis = Dialog.getCheckbox();																			// define the batch mode type

		setBatchMode(true);																								// Set batch mode on 


	//  Begining of the analysis loop if the Batch mode stack option is disabled

if ( Stack_analysis == false) {

File.makeDirectory(intermediate_results_directory);																		// Create temporary directory within the results location


for (p=0; p<number_of_tif; p++) {																						// Beginning of main analysis loop
	
	// Open the image and make duplicates for each workflow, close the orginal for safety
	
    showProgress(p+1, number_of_tif);																					// Update progress bar within ImageJ status bar
	interm_results_current = intermediate_results_directory+file_shortname[p]+File.separator; 							// Concatenate the path and file name for interm_results_current
	File.makeDirectory(interm_results_current);																			// Create a directory in intermediate_results_directory
	open(source_directory + file_fullname[p]);																			// Load the image rank p
	resetMinAndMax();																									// Reset the intensity scale (to make predicatable results in case autoscale is default)
	run("8-bit");																										// Transform image into 8-bit
	run("Duplicate...", "image"); rename("image");																		// Image is duplicated and renamed image
	run("Enhance Contrast", "saturated=0.35");																			// Autoscale the intensity signal according to user's ROI
	run("Select None");																									// Remove the manual drawn ROI
	run("Duplicate...", "skeleton"); rename("skeleton");																// Image is duplicated and renamed skeleton
	run("Duplicate...", "edges"); rename("edges");																		// Image is duplicated and renamed edges
	run("Duplicate...", "skeleton"); rename("merge");																	// Image is duplicated and renamed merge
	close(file_fullname[p]);																							// Safety precaution: close the original to avoid overwriting the raw data

	// Edge detection 
	
		selectWindow("edges");																							// Select the copy of the original image called edges
		run("Duplicate...", "edges"); rename("edges1");																	// Image is duplicated and renamed edges1
		selectWindow("edges1");																							// Selection of the safe copy of edges
		setThreshold(threshold_cell_edges, 255);																		// Set threshold values for edges detection
		run("Convert to Mask");																							// Transform the thresolded image into mask
				
		if (HoleEdge == true) {																								// Amazing trick to close the holes at the edge without blanking the entire image! :D
			w=getWidth(); h=getHeight();																					// Measure width and height of the image (w and h)
			w1= w+1;																										// define variable based on w to avoid bugs
			h1= h+1;																										// define variable based on h to avoid bugs
			run("Invert");																									// Turns the mask intos zeros
			run("Canvas Size...", "width="+w1+" height="+h1+" position=Top-Left");											// Reframe the image with line of 1 pixel for padding top left
			//run("Make Binary");																							// Reset image type
			run("Invert");																									// Turns the mask back into ones																															
			run("Fill Holes");																								// Fill in the holes within the mask
			run("Canvas Size...", "width="+w+" height="+h+" position=Top-Left zero");										// Remove the added padding on top left
			//run("Make Binary");																							// Reset image type
			run("Invert");																									// Turns the mask into zeros
			run("Canvas Size...", "width="+w1+" height="+h1+" position=Bottom-Right");										// Reframe the image with line of 1 pixel for padding bottom right
			//run("Make Binary");																							// Reset image type
			run("Invert");																									// Turns the mask back into ones																																			
			run("Fill Holes");																								// Fill in the holes within the mask
			run("Canvas Size...", "width="+w+" height="+h+" position=Bottom-Right zero");										// Remove the added padding on bottom right
		}																															//

		// Perform closing of the holes within the mask
		
		if (HoleFill == true) {																									// |
			run("Fill Holes");																										// |— User dependent loop to fill the holes (simpler version)
		}																																	// |

		// Run the commands for Open/Erode/Dilate functions
		
		run("Options...", "iterations="+n_iterations_open+" count=1 black pad do=Open");				// Run the Open command according to n_iterations_open
		run("Options...", "iterations="+n_cycles_erode_dilate+" count=1 black pad do=Erode");			// Run the Erode command according to n_cycles_erode_dilate
		run("Options...", "iterations="+n_cycles_erode_dilate+" count=1 black pad do=Dilate");			// Run the Dilate command according to n_cycles_erode_dilate
		
		// remove all the detected object that are too far from the cell edges

		if (n_distance_from_edges != 0) {																									// |
						
		selectWindow("edges1");	run("Duplicate...", "edges1"); rename("edges2"); 					// Egdes1 is duplicated and renamed edges2
		selectWindow("edges2"); run("Duplicate...", "edges2");	rename("edges3"); 					// Egdes1 is duplicated and renamed edges3
		selectWindow("edges2");																		// Select edges2
		run("Options...", "iterations="+n_distance_from_edges+" count=1 black pad do=Dilate");	 	 // maximal distance from edges, user input
		run("Invert");																									// Turns the mask back into ones																																				
		imageCalculator("Add create", "edges1","edges2");											// create an image that will contain only the area that contain possible filopodia
		selectWindow("edges1"); run("Close"); 
		selectWindow("edges2"); run("Close");														// close the unnecessary images
		selectWindow("Result of edges1"); rename("edges1");											// Rename to have the correct name for the following analysis
			}		
			
		// Filopodia detection 	
		selectWindow("skeleton");																	// Select the copy of the original image called skeleton
		run("Duplicate...", "skeleton"); rename("skeleton1");										// Image is duplicated and renamed edges1
		selectWindow("skeleton1");																	// Selection of the safe copy of skeleton

		// CLAHE command if required
		if (use_clahe == true) {																							// CLAHE: improves detection of faint filopodia but must remove if image is noisy
			run("Enhance Local Contrast (CLAHE)", "blocksize=127 histogram=256 maximum=3 mask=*None*");
		}
		
		// Convolve command if required		
		if (use_convolve == true) {																							// Convolution filter with fairly conservative kernel
			run("Convolve...", "text1=[-1 -1 -1 -1 -1\n-1 -1 -1 -1 -1\n-1 -1 24 -1 -1\n-1 -1 -1 -1 -1\n-1 -1 -1 -1 -1\n]");
		}
		run("Despeckle");																								// Remove artefacts induced by convolved
		run("Despeckle");																								// Remove artefacts induced by convolved
				
		// Drawing and identification of filopodia
		setThreshold(filopodia_threshold, 255);																			// Set threshold values for filopodia detection
			
		run("Convert to Mask");																							// Transform the thresolded image into mask
		run("Analyze Particles...", "size=8-Infinity pixel circularity=0.00-0.80 show=Masks clear in_situ");			// Filopodia drawing 
		
		
	
	// Extraction of filopodia
	
	imageCalculator("Subtract create", "skeleton1" , "edges1");																	// Filopodia extraction sequence
	selectWindow("Result of skeleton1"); rename("Result of skeleton");															// Select and rename the result of the image calculator
	setThreshold(80, 255);																										// Set threshold values for filopodia measurements
	run("Analyze Particles...", "size="+filopodia_min_size+"-Infinity pixel circularity=0.00-1 show=Masks clear in_situ");		// Filopodia drawing using filopodia_min_size
	run("Options...", "iterations="+filopodia_repair+" count=1 black pad do=Close");											// Filopodia repair using filopodia_repair
	run("Skeletonize (2D/3D)");																									// Run the Skeletonize (2D/3D) command (no user input, hard wired)
	run("Analyze Skeleton (2D/3D)", "prune=none show display");																	// Filopodia measurement
	selectWindow("Branch information");																							// Select the Branch information provided by the plugin used above
	IJ.renameResults("FilopodiaLength");																						// Rename the Branch information table as FilopodiaLength
	selectWindow("Results"); run("Close");																						// Select the Results table from the plugin and close it 
	setOption("BlackBackground", true);
	
	selectWindow("Tagged skeleton");																					// select image tagged skeleton and improve it for better filopodia validation
	run("Duplicate...", "Tagged skeleton2"); rename("Tagged skeleton2"); selectWindow("Tagged skeleton2");				// Image is duplicated, renamed Tagged skeleton2, and selected 
	run("Threshold...");
	setThreshold(3, 255);
	setOption("BlackBackground", true);
	run("Convert to Mask");																								// Image is transformed to a binary image
	run("Options...", "iterations=1 count=1 black pad do=Dilate");														// Dilate is applied to make the detected filopodia bigger
	run("8-bit");
	run("Merge Channels...", "c6=[Tagged skeleton2] c4=[merge] keep");													// Create a merged composite to inspect accuracy of extraction
		
			
		selectWindow("Result-labeled-skeletons");																		// Select the image Result-labeled-skeletons
		saveAs("Tiff",interm_results_current+file_shortname[p]+" - Result-labeled-skeletons.tif");						// Save the image Result-labeled-skeletons with prefix of current filename
		selectWindow("RGB");																							// Select the composite RGB
		saveAs("Tiff",results_directory+file_shortname[p]+" -Tagged skeleton RGB.tif");									// Save the image composite RGB with prefix of current filename
		selectWindow("Tagged skeleton");																				// Select the image Tagged skeleton
		saveAs("Tiff",interm_results_current+file_shortname[p]+" -Tagged skeleton.tif");								// Save the image Tagged skeleton with prefix of current filename
		selectWindow("skeleton1");																						// Select the image skeleton1
		saveAs("Tiff",interm_results_current+file_shortname[p]+" - skeleton.tif");										// Save the image skeleton1 with prefix of current filename
																			
		


		// Beginning of the contour detection 

		// File manipulation if user did not define a maximal distance from the cell edges for filopodia detection
		
		if (n_distance_from_edges != 0) {
		selectWindow("edges1"); run("Close");																		// Select the image edges1 and close it
		selectWindow("edges3");	run("Duplicate...", "edges1"); rename("edges1");									// Image is duplicated and renamed edges2
		selectWindow("edges1");																						// Select the image edges1
		run("Duplicate...", "contour"); rename("contour");															// Image is duplicated and renamed contour
            
   } 

   // File manipulation if user defined a maximal distance from the cell edges for filopodia detection
   else {
   	
   		selectWindow("edges1");																					// Select the image edges1
		run("Duplicate...", "edges2"); rename("edges2");														// Image is duplicated and renamed edges2
		selectWindow("edges2");																					// Select the image edges2
		run("Duplicate...", "edges2"); rename("contour");														// Image is duplicated and renamed contour
      
   }   
		
		// Contour detection 
				
		run("Options...", "iterations="+Contour_close+" count=1 black pad do=Close");										// Run the Close command 
		run("Options...", "iterations="+Contour_erode+" count=1 black pad do=Erode");										// Run the Erode command 
		run("Options...", "iterations="+Contour_dilate+" count=1 black pad do=Dilate");										// Run the Dilate command 
		run("Convolve...", "text1=[0	0	0	-1	-1	-1	0	0	0\n		 0	-1	-1	-3	-3	-3	-1	-1	0\n		 0	-1	-3	-3	-1	-3	-3	-1	0\n		-1	-3	-3	6	13	6	-3	-3	-1\n		-1	-3	-1	13	24	13	-1	-3	-1\n		-1	-3	-3	6	13	6	-3	-3	-1\n		 0	-1	-3	-3	-1	-3	-3	-1	0\n		 0	-1	-1	-3	-3	-3	-1	-1	0\n		 0	0	0	-1	-1	-1	0	0	0\n]"); // Run the Convolve command (no user input, hard wired)
		run("Skeletonize (2D/3D)");																							// Run the Skeletonize (2D/3D) command (no user input, hard wired)
	

		// Mesure the contour length
		selectWindow("contour");																						// Select the image that has been modified for Edges detection
		run("Analyze Skeleton (2D/3D)", "prune=none show display");														// Run the Analyze Skeleton (2D/3D) command (no user input, hard wired)
		selectWindow("Branch information");																				// Select the Branch information provided by the plugin used above
		IJ.renameResults("EdgeLength");																					// Rename the Branch information table as Edge information
		selectWindow("Results"); run("Close");																			// Select the Results table from the plugin and close it 
		selectWindow("contour-labeled-skeletons");																		// Select the image contour-labeled-skeletons created above
		run("8-bit");																									// Convert to 8-bit depth intensity range
		saveAs("Tiff",interm_results_current+file_shortname[p]+" -contour.tif");										// Save the image contour-labeled-skeletons with prefix of current filename
		selectWindow("edges1");																							// Select the image edges1
		saveAs("Tiff",interm_results_current+file_shortname[p]+" - edges.tif");											// Save the image edges1 with prefix of current filename
		run("Close All");																								// Close all the open image windows (not the tables)
	
		selectWindow("FilopodiaLength"); IJ.renameResults("Results");													// Rename table to Results to allow interaction
		nb_filopodia = nResults;																						// Count the number of filopodia in the current image
		for (i=0; i<nb_filopodia; i++) {																				//  |
			FilopMeas = getResult("Branch length", i);																	//  |—Save each line into FilopMeas and keep on concatenating it with itself within matrix
			FilopMeasMatrix = Array.concat(FilopMeasMatrix,FilopMeas);													//  |
		}																												//  |
		selectWindow("Results"); IJ.renameResults("FilopodiaLength");													// Rename table back to FilopodiaLength to stop interaction
		selectWindow("EdgeLength"); IJ.renameResults("Results");														// Rename table to Results to allow interaction
		nd_edges = nResults;																							// Count the number of edges in the current image
		for (i=0; i<nd_edges; i++) {																					//  |
			EdgeMeas = getResult("Branch length", i);																	//  |—Save each line into EdgeMeas and keep on concatenating it with itself within matrix
			EdgeMeasMatrix = Array.concat(EdgeMeasMatrix,EdgeMeas);														//  |
		}																												//  |
		selectWindow("Results"); IJ.renameResults("EdgeLength");														// Rename table back to EdgeLength to stop interaction
		setResult("Filopodia length", 0, 0); setResult("Edge length", 0, 0);											// Create an empty table with 2 column headers
		updateResults();																								// Haha ImageJ seems to need that to actually update the results table display
		for (i=0; i<nb_filopodia; i++) {																				//  |
			setResult("Filopodia length", i, FilopMeasMatrix[i+1]);														//  |—Transfer the FilopMeasMatrix into the new Results table, row by row
		}																												//  |
		for (i=0; i<nd_edges; i++) {																					//  |
			setResult("Edge length", i, EdgeMeasMatrix[i+1]);															//  |—Transfer the EdgeMeasMatrix into the new Results table, row by row
		}																												//  |
		
		FilopMeasMatrix = "";																							// Cleanup of the variable FilopMeasMatrix
		EdgeMeasMatrix = "";																							// Cleanup of the variable EdgeMeasMatrix
		
		selectWindow("Results"); IJ.renameResults("FiloQuant");															// Rename table FiloQuant because it sounds better
		selectWindow("FiloQuant");																						// Select the FiloQuant table
		saveAs("Results", results_directory+file_shortname[p]+" - Results.csv");										// Save the FiloQuant table with prefix of current filename
		run("Close");																									// Close the FiloQuant table
		selectWindow("FilopodiaLength"); run("Close");																	// Close the FilopodiaLength table
		selectWindow("EdgeLength");	run("Close");																		// Close the EdgeLength table
		setResult("Settings", 0, "Edge detection: Threshold for cell edges") ;											// Save the header for threshold value used for cell edges
		setResult("Value", 0, threshold_cell_edges) ;																	// Save the threshold value used for cell edges
		setResult("Settings", 1, "Edge detection: Number of iterations for Open") ;										// Save the header for value of open cycles used
		setResult("Value", 1, n_iterations_open) ;																		// Save the value of open cycles used
		setResult("Settings", 2, "Edge detection: Number of iterations for Erode") ;									// Save the header for value of erode cycles used
		setResult("Value", 2, n_cycles_erode_dilate) ;																	// Save the value of erode cycles used
		setResult("Settings", 3, "Edge detection: Fill holes on edges?") ;												// Save the header for use of Fill Edges command
		setResult("Value", 3, HoleEdge) ;																				// Save the header for use of Fill Edges command
		setResult("Settings", 4, "Edge detection: Fill Holes?") ;														// Save the header for use of Fill Holes command
		setResult("Value", 4, HoleFill) ;																				// Save the header for use of Fill Holes command
		setResult("Settings", 5, "Filopodia detection: Threshold for filopodia") ;										// Save the header for threshold value used for filopodia
		setResult("Value", 5, filopodia_threshold) ;																	// Save the header for threshold value used for filopodia
		setResult("Settings", 6, "Filopodia detection: Filopodia minimum size") ;										// Save the header for minimum value used for filopodia size
		setResult("Value", 6, filopodia_min_size) ;																		// Save the header for minimum value used for filopodia size
		setResult("Settings", 7, "Filopodia detection: Use convolve to improve filopodia detection?") ;					// Save the header for use of convolution for filopodia detection
		setResult("Value", 7, use_convolve) ;																				// Save the header for use of convolution for filopodia detection
		setResult("Settings", 8, "Filopodia detection: Use local contrast enhancement to improve filopodia detection?");	// Save the header for use of CLAHE
		setResult("Value", 8, use_clahe) ;																					// Save the info for use of CLAHE
		setResult("Settings", 9, "Filopodia detection: Maximal distance from edges");										// Save the header for Number of iterations for Dilate in contour detection
		setResult("Value", 9, n_distance_from_edges) ;																		// Save the value Contour_dilate
		setResult("Settings", 10, "Contour detection: Number of iterations for Close");										// Save the header for Number of iterations for Close in contour detection
		setResult("Value", 10, Contour_close) ;																				// Save the value Contour_close
		setResult("Settings", 11, "Contour detection: Number of iterations for Erode");										// Save the header for Number of iterations for Erode in contour detection
		setResult("Value", 11, Contour_erode) ;																				// Save the value Contour_erode
		setResult("Settings", 12, "Contour detection: Number of iterations for Dilate");									// Save the header for Number of iterations for Dilate in contour detection
		setResult("Value", 12, Contour_dilate) ;																			// Save the value Contour_dilate
		updateResults();																									// Haha ImageJ seems to need that to actually update the results table display
		selectWindow("Results");																							// Select the Results table (the one with the settings)
		saveAs("Results", interm_results_current+file_shortname[p]+" - settings.csv");										// Save the Settings table with prefix of current filename
		selectWindow("Results"); run("Close");																				// Close the Results window
																															// End of the results saving sub-loop
	
}		// End of main analysis loop for the single tiff batch mode

} 		// End of main analysis loop for the single tiff batch mode


		// Begining of the analysis loop if the Batch mode stack option is enabled

if ( Stack_analysis == true) {

// beginning of the stack loop
		for (p=0; p<number_of_tif; p++) {
	setBatchMode(true);	//set batch mode true 
	
	// Open the stacks create the folders and split the stacks into slices
	
 	showProgress(p+1, number_of_tif);																		// Update progress bar within ImageJ status bar
	open(source_directory + file_fullname[p]);																// Load the image rank p
	resetMinAndMax();																						// Reset the intensity scale (to make predicatable results in case autoscale is default)
	stack_results_current = results_directory+file_shortname[p]+File.separator; 							// Concatenate the path and file name for interm_results_current
	File.makeDirectory(stack_results_current);																// Create a directory in intermediate_results_directory

	image_sequence_directory = stack_results_current+"image_sequence"+File.separator;						// define the various folders location
	Tagged_skeleton_RGB_directory = stack_results_current+"Tagged_skeleton_RGB"+File.separator;
	skeleton_directory = stack_results_current+"skeleton"+File.separator;
	contour_directory = stack_results_current+"contour"+File.separator;
	edges_directory = stack_results_current+"edges"+File.separator;
	Tagged_skeleton_directory = stack_results_current+"Tagged_skeleton"+File.separator;
	Tracking_file_directory = stack_results_current+"Tracking_file"+File.separator;
	Result_file_directory = stack_results_current+"Result_file"+File.separator;

		File.makeDirectory(image_sequence_directory);													// Create temporary directory within the results location
		File.makeDirectory(Tagged_skeleton_RGB_directory);												// Create temporary directory within the results location
		File.makeDirectory(skeleton_directory);															// Create temporary directory within the results location
		File.makeDirectory(contour_directory);															// Create temporary directory within the results location
		File.makeDirectory(edges_directory);															// Create temporary directory within the results location
		File.makeDirectory(Tagged_skeleton_directory);													// Create temporary directory within the results location
		File.makeDirectory(Tracking_file_directory);													// Create temporary directory within the results location
		File.makeDirectory(Result_file_directory);														// Create temporary directory within the results location


		run("Image Sequence... ", "format=TIFF save="+image_sequence_directory);  						 // divide the stacks in an image sequence to be processed separately

	number_of_slice = 0;																				// Initialization of file counter
	slice_name_index = 0;

	all_slice_list = getFileList(image_sequence_directory);												// Create an array with the name of all the elements in the folder
	number_slice = lengthOf(all_slice_list);															// Count the total number of elements in the source folder
	for (i=0; i<number_slice; i++) {																							// |
	if (endsWith(all_slice_list[i], ".tiff") || endsWith(all_slice_list[i], ".tif")) {								// |
		number_of_slice = number_of_slice + 1;															// |— Count the number of TIFF/TIF files
	}																																		// |
}																																			// |
	if (number_of_slice == 0) {																										//  ||
	exit("Duh! This folder doesn't contain any compatible files!");										//  ||— Clean exit if no compatible file present in the location
}																																			//  ||


	// Creating array for full and extensionless filenames
	

	slice_shortname=newArray(number_of_slice);																				// Array allocation
	slice_fullname=newArray(number_of_slice);																					// Array allocation
	
	for (i=0; i<number_slice; i++) {																							// 
		length_name=lengthOf(all_slice_list[i]);																				// 
	if (endsWith(all_slice_list[i], ".tiff")) {																						// |
		slice_fullname[slice_name_index]=all_files_list2[i];																	// |
		slice_shortname[slice_name_index]=substring(all_slice_list[i],0,length_name-5);						// |— Storage of filename for TIFF file
		slice_name_index = slice_name_index + 1;																				// |
		}																																		// |
	if (endsWith(all_slice_list[i], ".tif")) {																						//  ||
		slice_fullname[slice_name_index]=all_slice_list[i];																	//  ||
		slice_shortname[slice_name_index]=substring(all_slice_list[i],0,length_name-4);						//  ||— Storage of filename for TIF file
		slice_name_index = slice_name_index + 1;																				//  ||
	}																																			//  ||
}																																			// 

	//save the settings
		setResult("Settings", 0, "Edge detection: Threshold for cell edge") ;													// Save the header for threshold value used for cell edges
		setResult("Value", 0, threshold_cell_edges) ;																			// Save the threshold value used for cell edges
		setResult("Settings", 1, "Edge detection: Number of iterations for Open") ;												// Save the header for value of open cycles used
		setResult("Value", 1, n_iterations_open) ;																				// Save the value of open cycles used
		setResult("Settings", 2, "Edge detection: Number of iterations for Erode") ;											// Save the header for value of erode cycles used
		setResult("Value", 2, n_cycles_erode_dilate) ;																			// Save the value of erode cycles used
		setResult("Settings", 3, "Edge detection: Fill holes on edges?") ;														// Save the header for use of Fill Edges command
		setResult("Value", 3, HoleEdge) ;																						// Save the header for use of Fill Edges command
		setResult("Settings", 4, "Edge detection: Fill Holes?") ;																// Save the header for use of Fill Holes command
		setResult("Value", 4, HoleFill) ;																						// Save the header for use of Fill Holes command
		setResult("Settings", 5, "Filopodia detection: Threshold for filopodia") ;												// Save the header for threshold value used for filopodia
		setResult("Value", 5, filopodia_threshold) ;																			// Save the header for threshold value used for filopodia
		setResult("Settings", 6, "Filopodia detection: Filopodia minimum size") ;												// Save the header for minimum value used for filopodia size
		setResult("Value", 6, filopodia_min_size) ;																				// Save the header for minimum value used for filopodia size
		setResult("Settings", 7, "Filopodia detection: Use convolve to improve filopodia detection?") ;							// Save the header for use of convolution for filopodia detection
		setResult("Value", 7, use_convolve) ;																					// Save the header for use of convolution for filopodia detection
		setResult("Settings", 8, "Filopodia detection: Use local contrast enhancement to improve filopodia detection?");		// Save the header for use of CLAHE
		setResult("Value", 8, use_clahe) ;																						// Save the info for use of CLAHE
		setResult("Settings", 9, "Filopodia detection: Maximal distance from edges");											// Save the header for Number of iterations for Dilate in contour detection
		setResult("Value", 9, n_distance_from_edges) ;																			// Save the value Contour_dilate
		setResult("Settings", 10, "Contour detection: Number of iterations for Close");											// Save the header for Number of iterations for Close in contour detection
		setResult("Value", 10, Contour_close) ;																					// Save the value Contour_close
		setResult("Settings", 11, "Contour detection: Number of iterations for Erode");											// Save the header for Number of iterations for Erode in contour detection
		setResult("Value", 11, Contour_erode) ;																					// Save the value Contour_erode
		setResult("Settings", 12, "Contour detection: Number of iterations for Dilate");										// Save the header for Number of iterations for Dilate in contour detection
		setResult("Value", 12, Contour_dilate) ;																				// Save the value Contour_dilate
		
		updateResults();																										// Haha ImageJ seems to need that to actually update the results table display
		selectWindow("Results");																								// Select the Results table (the one with the settings)
		saveAs("Results", stack_results_current+" - settings.csv");																// Save the Settings table with prefix of current filename
		selectWindow("Results"); run("Close");												
		
// Main analysis loop, 1 iteration per tif/tiff file

	for (p2=0; p2<number_of_slice; p2++) {																						// Beginning of main analysis loop

		print(slice_fullname[p2]);
	// Open the image and make duplicates for each workflow, close the orginal for safety
	
		open(image_sequence_directory+slice_fullname[p2]);																		// Load the image rank p
		resetMinAndMax();																										// Reset the intensity scale (to make predicatable results in case autoscale is default)
		run("8-bit");																											// Transform image into 8-bit
		run("Duplicate...", "image"); rename("image");																			// Image is duplicated and renamed image
		run("Enhance Contrast", "saturated=0.35");																				// Autoscale the intensity signal according to user's ROI
		run("Select None");																										// Remove the manual drawn ROI
		run("Duplicate...", "skeleton"); rename("skeleton");																	// Image is duplicated and renamed skeleton
		run("Duplicate...", "edges"); rename("edges");																			// Image is duplicated and renamed edges
		run("Duplicate...", "skeleton"); rename("merge");																		// Image is duplicated and renamed merge
		close(slice_fullname[p2]);																								// Safety precaution: close the original to avoid overwriting the raw data

	// Edge detection 
	
		selectWindow("edges");																									// Select the copy of the original image called edges
		run("Duplicate...", "edges"); rename("edges1");																			// Image is duplicated and renamed edges1
		selectWindow("edges1");																									// Selection of the safe copy of edges
		setThreshold(threshold_cell_edges, 255);																				// Set threshold values for edges detection
		run("Convert to Mask");																									// Transform the thresolded image into mask
		
		
		// Perform closing of holes in the mask and at the edges of the image
		
		if (HoleEdge == true) {																							// Amazing trick to close the holes at the edge without blanking the entire image! :D
			w=getWidth(); h=getHeight();																				// Measure width and height of the image (w and h)
			w1= w+1;																									// define variable based on w to avoid bugs
			h1= h+1;																									// define variable based on h to avoid bugs
		run("Invert");																									// Turns the mask intos zeros
		run("Canvas Size...", "width="+w1+" height="+h1+" position=Top-Left");											// Reframe the image with line of 1 pixel for padding top left
		run("Invert");																									// Turns the mask back into ones																															
		run("Fill Holes");																								// Fill in the holes within the mask
		run("Canvas Size...", "width="+w+" height="+h+" position=Top-Left zero");										// Remove the added padding on top left
		run("Invert");																									// Turns the mask into zeros
		run("Canvas Size...", "width="+w1+" height="+h1+" position=Bottom-Right");										// Reframe the image with line of 1 pixel for padding bottom right
		run("Invert");																									// Turns the mask back into ones																																			
		run("Fill Holes");																								// Fill in the holes within the mask
		run("Canvas Size...", "width="+w+" height="+h+" position=Bottom-Right zero");									// Remove the added padding on bottom right
		}																																			//

		// Perform closing of the holes within the mask
		
		if (HoleFill == true) {																									// |
			run("Fill Holes");																										// |— User dependent loop to fill the holes (simpler version)
		}																																	// |

		// Run the commands for Open/Erode/Dilate functions
		
		run("Options...", "iterations="+n_iterations_open+" count=1 black pad do=Open");					// Run the Open command according to n_iterations_open
		run("Options...", "iterations="+n_cycles_erode_dilate+" count=1 black pad do=Erode");			// Run the Erode command according to n_cycles_erode_dilate
		run("Options...", "iterations="+n_cycles_erode_dilate+" count=1 black pad do=Dilate");			// Run the Dilate command according to n_cycles_erode_dilate
		
		// remove all the detected object that are too far from the cell edges

		// remove all the detected object that are too far from the cell edges

		if (n_distance_from_edges != 0) {																									// |
						
		selectWindow("edges1");	run("Duplicate...", "edges1"); rename("edges2"); 				// Egdes1 is duplicated and renamed edges2
		selectWindow("edges2"); run("Duplicate...", "edges2");	rename("edges3"); 				// Egdes1 is duplicated and renamed edges3
		selectWindow("edges2");																	// Select edges2
		run("Options...", "iterations="+n_distance_from_edges+" count=1 black pad do=Dilate");	   // maximal distance from edges, user input
		run("Invert");																									// Turns the mask back into ones																																				
		imageCalculator("Add create", "edges1","edges2");										// create an image that will contain only the area that contain possible filopodia
		selectWindow("edges1"); run("Close"); 
		selectWindow("edges2"); run("Close");													// close the unnecessary images
		selectWindow("Result of edges1"); rename("edges1");										// Rename to have the correct name for the following analysis
			}		
		
																										

	// Filopodia detection 
	
		selectWindow("skeleton");																								// Select the copy of the original image called skeleton
		run("Duplicate...", "skeleton"); rename("skeleton1");														// Image is duplicated and renamed edges1
		selectWindow("skeleton1");																							// Selection of the safe copy of skeleton

		// CLAHE command if required

		if (use_clahe == true) {																									// CLAHE: improves detection of faint filopodia but must remove if image is noisy
			run("Enhance Local Contrast (CLAHE)", "blocksize=127 histogram=256 maximum=3 mask=*None*");
		}
		
		// Convolve command if required
		
		if (use_convolve == true) {																							// Convolution filter with fairly conservative kernel
			run("Convolve...", "text1=[-1 -1 -1 -1 -1\n-1 -1 -1 -1 -1\n-1 -1 24 -1 -1\n-1 -1 -1 -1 -1\n-1 -1 -1 -1 -1\n]");
		}
		
		run("Despeckle");																								// Remove artefacts induced by convolved
		run("Despeckle");																								// Remove artefacts induced by convolved
				
		// Drawing and identification of filopodia
		
		setThreshold(filopodia_threshold, 255);																			// Set threshold values for filopodia detection
		
		
		//setOption("BlackBackground", true);																			// Warning: system wide modification here... Not necessary??? Double check later
		run("Convert to Mask");																									// Transform the thresolded image into mask
		run("Analyze Particles...", "size=8-Infinity pixel circularity=0.00-0.80 show=Masks clear in_situ");			// Filopodia drawing 
		
		
	
	// Extraction of filopodia
	
		imageCalculator("Subtract create", "skeleton1" , "edges1");													// Filopodia extraction sequence
		selectWindow("Result of skeleton1"); rename("Result of skeleton");										// Select and rename the result of the image calculator
		setThreshold(80, 255);																										// Set threshold values for filopodia measurements
		run("Analyze Particles...", "size="+filopodia_min_size+"-Infinity pixel circularity=0.00-1 show=Masks clear in_situ");	// Filopodia drawing using filopodia_min_size
		run("Options...", "iterations="+filopodia_repair+" count=1 black pad do=Close");										// Filopodia repair using filopodia_repair
		run("Skeletonize (2D/3D)");																							// Run the Skeletonize (2D/3D) command (no user input, hard wired)
		run("Analyze Skeleton (2D/3D)", "prune=none show display");												// Filopodia measurement
		selectWindow("Branch information");																					// Select the Branch information provided by the plugin used above
		IJ.renameResults("FilopodiaLength");																					// Rename the Branch information table as FilopodiaLength
		selectWindow("Results"); run("Close");																				// Select the Results table from the plugin and close it 
		setOption("BlackBackground", true);
	
		selectWindow("Tagged skeleton");																					// select image tagged skeleton and improve it for better filopodia validation
		run("Duplicate...", "Tagged skeleton2"); rename("Tagged skeleton2"); selectWindow("Tagged skeleton2");				// Image is duplicated, renamed Tagged skeleton2, and selected 
		run("Threshold...");
		setThreshold(3, 255);
		setOption("BlackBackground", true);
		run("Convert to Mask");																								// Image is transformed to a binary image
		run("Options...", "iterations=1 count=1 black pad do=Dilate");														// Dilate is applied to make the detected filopodia bigger
		run("8-bit");
	
		run("Merge Channels...", "c6=[Tagged skeleton2] c4=[merge] keep");														// Create a merged composite to inspect accuracy of extraction
		
	// Make the tracking file
		selectWindow("Tagged skeleton"); run("Duplicate...", "tracking"); rename("tracking"); 									// select image tagged skeleton, duplicate and rename tracking
		selectWindow("tracking"); run("Threshold..."); setThreshold(3, 255); setOption("BlackBackground", true); run("Convert to Mask"); run("Ultimate Points");		// select tracking and modify it for filopodia tracking
			
	
	// save files				
		
		selectWindow("RGB");																									// Select the composite RGB
		saveAs("Tiff",Tagged_skeleton_RGB_directory+slice_shortname[p2]+" -Tagged skeleton RGB.tif");							// Save the image composite RGB with prefix of current filename
		selectWindow("Tagged skeleton");																						// Select the image Tagged skeleton
		saveAs("Tiff",Tagged_skeleton_directory+slice_shortname[p2]+" -Tagged skeleton.tif");									// Save the image Tagged skeleton with prefix of current filename
		selectWindow("skeleton1");																								// Select the image skeleton1
		saveAs("Tiff",skeleton_directory+slice_shortname[p2]+" - skeleton.tif");												// Save the image skeleton1 with prefix of current filename
		selectWindow("tracking");																								// Select the image tracking
		saveAs("Tiff",Tracking_file_directory+slice_shortname[p2]+" -Tagged skeleton.tif");										// Save the image Tagged skeleton with prefix of current filename
		selectWindow("edges1"); 																								// Close all the open windows except edges1
		

	//  Beginning of Contour detection 																	


	// Contour detection if the user choose a maximal distance from filopodia tips 
		if (n_distance_from_edges != 0) {																				// Checking if the user inputed a maximal distance from filopodia tips
		selectWindow("edges1"); run("Close");																			// Select the image edges1 and close it
		selectWindow("edges3");	run("Duplicate...", "edges1"); rename("edges1");										// Image is duplicated and renamed edges2
		selectWindow("edges1");	run("Duplicate...", "contour"); rename("contour");										// Edges1 is duplicated and renamed contour												
																			
      
      
   } 

  	 // Contour detection if no maximal distance from filopodia tips was chosen
   else {
   	
   		selectWindow("edges1");																							// Select the image edges1
		run("Duplicate...", "edges2"); rename("edges2");																// Image is duplicated and renamed edges2
		selectWindow("edges2");																							// Select the image edges2
		run("Duplicate...", "edges2"); rename("contour");																// Image is duplicated and renamed contour
      
   }   
		
	// Contour detection 																	
																	
		run("Options...", "iterations="+Contour_close+" count=1 black pad do=Close");										// Run the Close command 
		run("Options...", "iterations="+Contour_erode+" count=1 black pad do=Erode");										// Run the Erode command 
		run("Options...", "iterations="+Contour_dilate+" count=1 black pad do=Dilate");										// Run the Dilate command 
		run("Convolve...", "text1=[0	0	0	-1	-1	-1	0	0	0\n		 0	-1	-1	-3	-3	-3	-1	-1	0\n		 0	-1	-3	-3	-1	-3	-3	-1	0\n		-1	-3	-3	6	13	6	-3	-3	-1\n		-1	-3	-1	13	24	13	-1	-3	-1\n		-1	-3	-3	6	13	6	-3	-3	-1\n		 0	-1	-3	-3	-1	-3	-3	-1	0\n		 0	-1	-1	-3	-3	-3	-1	-1	0\n		 0	0	0	-1	-1	-1	0	0	0\n]"); // Run the Convolve command (no user input, hard wired)
		run("Skeletonize (2D/3D)");																						// Run the Skeletonize (2D/3D) command (no user input, hard wired)
	

	// Mesure the contour length
		selectWindow("contour");																						// Select the image that has been modified for Edges detection
		run("Analyze Skeleton (2D/3D)", "prune=none show display");														// Run the Analyze Skeleton (2D/3D) command (no user input, hard wired)
		selectWindow("Branch information");																				// Select the Branch information provided by the plugin used above
		IJ.renameResults("EdgeLength");																					// Rename the Branch information table as Edge information
		selectWindow("Results"); run("Close");																			// Select the Results table from the plugin and close it 
		selectWindow("contour-labeled-skeletons");																		// Select the image contour-labeled-skeletons created above
		run("8-bit");																									// Convert to 8-bit depth intensity range
		saveAs("Tiff",contour_directory+slice_shortname[p2]+" -contour.tif");											// Save the image contour-labeled-skeletons with prefix of current filename
		selectWindow("edges1");																							// Select the image edges1
		saveAs("Tiff",edges_directory+slice_shortname[p2]+" - edges.tif");												// Save the image edges1 with prefix of current filename
		run("Close All");																								// Close all the open image windows (not the tables)
	
		selectWindow("FilopodiaLength"); IJ.renameResults("Results");													// Rename table to Results to allow interaction
		nb_filopodia = nResults;																						// Count the number of filopodia in the current image
		for (i=0; i<nb_filopodia; i++) {																						
			FilopMeas = getResult("Branch length", i);																	//  |—Save each line into FilopMeas and keep on concatenating it with itself within matrix
			FilopMeasMatrix = Array.concat(FilopMeasMatrix,FilopMeas);											
		}																																	
		selectWindow("Results"); IJ.renameResults("FilopodiaLength");													// Rename table back to FilopodiaLength to stop interaction
		selectWindow("EdgeLength"); IJ.renameResults("Results");														// Rename table to Results to allow interaction
		nd_edges = nResults;																							// Count the number of edges in the current image
		for (i=0; i<nd_edges; i++) {																							
			EdgeMeas = getResult("Branch length", i);																	//  |—Save each line into EdgeMeas and keep on concatenating it with itself within matrix
			EdgeMeasMatrix = Array.concat(EdgeMeasMatrix,EdgeMeas);										
		}																																	
		selectWindow("Results"); IJ.renameResults("EdgeLength");														// Rename table back to EdgeLength to stop interaction
		setResult("Filopodia length", 0, 0); setResult("Edge length", 0, 0);											// Create an empty table with 2 column headers
		updateResults();																								// Haha ImageJ seems to need that to actually update the results table display
		for (i=0; i<nb_filopodia; i++) {																						
			setResult("Filopodia length", i, FilopMeasMatrix[i+1]);														//  |—Transfer the FilopMeasMatrix into the new Results table, row by row
		}																																	
		for (i=0; i<nd_edges; i++) {																							
			setResult("Edge length", i, EdgeMeasMatrix[i+1]);															//  |—Transfer the EdgeMeasMatrix into the new Results table, row by row
		}																																	
		
		FilopMeasMatrix = "";																							// Cleanup of the variable FilopMeasMatrix
		EdgeMeasMatrix = "";																							// Cleanup of the variable EdgeMeasMatrix
		
		selectWindow("Results"); IJ.renameResults("FiloQuant");															// Rename table FiloQuant because it sounds better
		selectWindow("FiloQuant");																						// Select the FiloQuant table
		saveAs("Results", Result_file_directory+slice_shortname[p2]+" - Results.csv");									// Save the FiloQuant table with prefix of current filename
		run("Close");																									// Close the FiloQuant table
		selectWindow("FilopodiaLength"); run("Close");																	// Close the FilopodiaLength table
		selectWindow("EdgeLength");	run("Close");																		// Close the EdgeLength table

											
	
}										// end of the slice loop														// End of main analysis loop

	// create a temporal projection of the detected filopodia

		setBatchMode(false);																																					// disable batchmode to avoid bugs
		run("Image Sequence...", "starting=1 sort open="+Tagged_skeleton_directory); 																							// open the tagged skeleton folder as a stack
		run("Threshold..."); setOption("BlackBackground", true); setThreshold(8, 255); run("Convert to Mask", "method=Default background=Dark calculate black"); 				// convert into 8 bit stack
		run("Temporal-Color Code", "lut=Fire create");																															// create the time projection using the FIRE Lut
		selectWindow("MAX_colored");  saveAs("Tiff",stack_results_current+slice_shortname[p]+"temporal projection.tif");														// save the time projection
		run("Close All");																																						// Close all the open image windows (not the tables)
		setBatchMode(true);																																						//enable batch mode after the temporal stack has been processed

}		// end of the stack loop

}		// end of the IF (stack)
