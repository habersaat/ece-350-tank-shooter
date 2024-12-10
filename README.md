# ece-350-tank-shooter
Note that in order to run this for yourself, you will need to update file paths in the following locations.

VGAController.v (line 20)
localparam MEM_FILES_PATH = "C:/Users/hah50/Downloads/ece-350-tank-shooter/mem_files/";

Wrapper.v (line 100)
localparam INSTR_FILE = "C:/Users/hah50/Downloads/ece-350-tank-shooter/CPU/Test Files/Memory Files/tank_shooter";

You will likely also need to configure the Vivado project to a directory of your choosing.