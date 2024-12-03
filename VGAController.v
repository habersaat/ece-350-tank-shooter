`timescale 1 ns/ 100 ps
module VGAController(     
	input clk, 			// 100 MHz System Clock
	input reset, 		// Reset Signal
	output hSync, 		// H Sync Signal
	output vSync, 		// Veritcal Sync Signal
	output [3:0] VGA_R,  // Red Signal Bits
	output [3:0] VGA_G,  // Green Signal Bits
	output [3:0] VGA_B,  // Blue Signal Bits
	inout ps2_clk,
	inout ps2_data,
	input CPU_RESETN, BTNC, BTNU, BTNL, BTNR, BTND,
	input [10:1] JD);
	
	// Lab Memory Files Location
	localparam MEM_FILES_PATH = "C:/Users/hah50/Downloads/ece-350-tank-shooter/mem_files/";
	
	reg [9:0] currX;
	reg [10:0] currY;
	
	// Boolan for whether x,y in square:
	wire isInSquare;
	assign isInSquare = (x >= currX && x < currX + SPRITE_SIZE) && (y >= currY && y < currY + SPRITE_SIZE);
	
	// Always loop to update on active
	always @ (posedge screenEnd) begin
	   if (RIGHT || BTNR)
	       if (currX + SPRITE_SIZE + 3 < VIDEO_WIDTH)
	           currX <= currX + 3;
	   if (LEFT || BTNL)
	       if (currX-3 > 1)
	           currX <= currX - 3;
	end
	always @ (posedge screenEnd) begin
	   if (DOWN || BTND)
	       if (currY + SPRITE_SIZE + 3 < VIDEO_HEIGHT)
	           currY <= currY + 3;
	   if (UP || BTNU)
	       if (currY - 3 > 0)
	           currY <= currY - 3;   
	end
	       
	wire DOWN = JD[4];
	wire RIGHT = JD[3];
	wire LEFT = JD[2];
	wire UP = JD[1];
	
	// Clock divider 100 MHz -> 25 MHz
	wire clk25; // 25MHz clock

	reg[1:0] pixCounter = 0;      // Pixel counter to divide the clock
    assign clk25 = pixCounter[1]; // Set the clock high whenever the second bit (2) is high
	always @(posedge clk) begin
		pixCounter <= pixCounter + 1; // Since the reg is only 3 bits, it will reset every 8 cycles
	end

	// VGA Timing Generation for a Standard VGA Screen
	localparam 
		VIDEO_WIDTH = 640,  // Standard VGA Width
		VIDEO_HEIGHT = 480, // Standard VGA Height
		SPRITE_SIZE = 64;

	wire active, screenEnd;
	wire[9:0] x;
	wire[10:0] y;
	
	VGATimingGenerator #(
		.HEIGHT(VIDEO_HEIGHT), // Use the standard VGA Values
		.WIDTH(VIDEO_WIDTH))
	Display( 
		.clk25(clk25),  	   // 25MHz Pixel Clock
		.reset(reset),		   // Reset Signal
		.screenEnd(screenEnd), // High for one cycle when between two frames
		.active(active),	   // High when drawing pixels
		.hSync(hSync),  	   // Set Generated H Signal
		.vSync(vSync),		   // Set Generated V Signal
		.x(x), 				   // X Coordinate (from left)
		.y(y)); 			   // Y Coordinate (from top)	   

	// Image Data to Map Pixel Location to Color Address
	localparam 
		PIXEL_COUNT = VIDEO_WIDTH*VIDEO_HEIGHT, 	             // Number of pixels on the screen
		PIXEL_ADDRESS_WIDTH = $clog2(PIXEL_COUNT) + 1,           // Use built in log2 command
		BITS_PER_COLOR = 12, 	  								 // Nexys A7 uses 12 bits/color
		PALETTE_COLOR_COUNT = 256, 								 // Number of Colors available
		PALETTE_ADDRESS_WIDTH = $clog2(PALETTE_COLOR_COUNT) + 1; // Use built in log2 Command

	wire[PIXEL_ADDRESS_WIDTH-1:0] imgAddress;  	 // Image address for the image data
	wire[PALETTE_ADDRESS_WIDTH-1:0] colorAddr; 	 // Color address for the color palette
	assign imgAddress = x + 640*y;				 // Address calculated coordinate

	
	
	// Image Data to Map Pixel Location to Color Address
	localparam 
		SPRITE_PIXEL_COUNT =  SPRITE_SIZE * SPRITE_SIZE, 	             // Number of pixels on the screen
		SPRITE_PIXEL_ADDRESS_WIDTH = $clog2(SPRITE_PIXEL_COUNT) + 1;     // Use built in log2 command
	
    wire [9:0] sprite_x = x - currX;
    wire [10:0] sprite_y = y - currY;
    
    wire [SPRITE_PIXEL_ADDRESS_WIDTH-1:0] spriteAddress = sprite_x + (SPRITE_SIZE * sprite_y);				 // Address calculated active
    wire [PALETTE_ADDRESS_WIDTH-1:0] spriteColorAddr;
	
	RAM #(		
		.DEPTH(SPRITE_PIXEL_COUNT), 		            // Set RAM depth to contain every pixel
		.DATA_WIDTH(PALETTE_ADDRESS_WIDTH),             // Set data width according to the color palette
		.ADDRESS_WIDTH(SPRITE_PIXEL_ADDRESS_WIDTH),     // Set address with according to the pixel count
		.MEMFILE({MEM_FILES_PATH, "p1Tankimage.mem"}))            // Memory initialization
	ImageData2(
		.clk(clk), 						         // Falling edge of the 100 MHz clk
		.addr(spriteAddress),					 // Image data address
		.dataOut(spriteColorAddr),				 // Color palette address
		.wEn(1'b0)); 						     // We're always reading
	
	// Color Palette to Map Color Address to 12-Bit Color
	wire[BITS_PER_COLOR-1:0] spriteColorData; // 12-bit color data at current pixel
	
	RAM #(
		.DEPTH(PALETTE_COLOR_COUNT), 		       // Set depth to contain every color		
		.DATA_WIDTH(BITS_PER_COLOR), 		       // Set data width according to the bits per color
		.ADDRESS_WIDTH(PALETTE_ADDRESS_WIDTH),     // Set address width according to the color count
		.MEMFILE({MEM_FILES_PATH, "p1Tankcolors.mem"}))  // Memory initialization
	ColorPalette2(
		.clk(clk), 							   	   // Rising edge of the 100 MHz clk
		.addr(spriteColorAddr),					   // Address from the ImageData RAM
		.dataOut(spriteColorData),				   // Color at current pixel
		.wEn(1'b0)); 						       // We're always reading
	
	
	
	

	RAM #(		
		.DEPTH(PIXEL_COUNT), 				     // Set RAM depth to contain every pixel
		.DATA_WIDTH(PALETTE_ADDRESS_WIDTH),      // Set data width according to the color palette
		.ADDRESS_WIDTH(PIXEL_ADDRESS_WIDTH),     // Set address with according to the pixel count
		.MEMFILE({MEM_FILES_PATH, "image.mem"})) // Memory initialization
	ImageData (
		.clk(clk), 						 // Falling edge of the 100 MHz clk
		.addr(imgAddress),					 // Image data address
		.dataOut(colorAddr),				 // Color palette address
		.wEn(1'b0)); 						 // We're always reading

	// Color Palette to Map Color Address to 12-Bit Color
	wire[BITS_PER_COLOR-1:0] colorData; // 12-bit color data at current pixel

	RAM #(
		.DEPTH(PALETTE_COLOR_COUNT), 		       // Set depth to contain every color		
		.DATA_WIDTH(BITS_PER_COLOR), 		       // Set data width according to the bits per color
		.ADDRESS_WIDTH(PALETTE_ADDRESS_WIDTH),     // Set address width according to the color count
		.MEMFILE({MEM_FILES_PATH, "colors.mem"}))  // Memory initialization
	ColorPalette (
		.clk(clk), 							   	   // Rising edge of the 100 MHz clk
		.addr(colorAddr),					       // Address from the ImageData RAM
		.dataOut(colorData),				       // Color at current pixel
		.wEn(1'b0)); 						       // We're always reading
	

	// Assign to output color from register if active
	wire[BITS_PER_COLOR-1:0] colorOut; 			  // Output color 
	assign colorOut = active ? (isInSquare ? spriteColorData : colorData) : 12'd0; // When not active, output black

	// Quickly assign the output colors to their channels using concatenation
	assign {VGA_R, VGA_G, VGA_B} = colorOut;
endmodule