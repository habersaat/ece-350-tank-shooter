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
	input [10:1] JD,
	input [10:1] JC,
	input [2047:0] allBulletContents,
	input [127:0] allSpriteContents,
	input [63:0] allHealthContents);
	
	// Lab Memory Files Location
	localparam MEM_FILES_PATH = "C:/Users/hah50/Downloads/ece-350-tank-shooter/mem_files/";
	
	reg [9:0] currX1;
	reg [8:0] currY1;
	
	reg [9:0] currX2;
	reg [8:0] currY2;

	// Read in current x and y positions of the sprites
	integer i;
	always @(*) begin
		for (i = 0; i < 4; i = i + 1) begin
			// Extract 32 bits for each sprite
			case (i)
				0: currX1 = allSpriteContents[(i*32) +: 10]; // Extract 10 bits for x1
				1: currY1 = allSpriteContents[(i*32) +: 9];  // Extract 9 bits for y1
				2: currX2 = allSpriteContents[(i*32) +: 10]; // Extract 10 bits for x2
				3: currY2 = allSpriteContents[(i*32) +: 9];  // Extract 9 bits for y2
			endcase
		end
	end

	// Read in current health for each player
	reg [31:0] p1Health;
	reg [31:0] p2Health;
	always @(*) begin
		p1Health = allHealthContents[31:0]; // Extract 32 bits for p1 health
		p2Health = allHealthContents[63:32]; // Extract 32 bits for p2 health
	end

	// Boolan for whether x,y in square:
	wire p1isInSquare;
	assign p1isInSquare = (x >= currX1 && x < currX1 + SPRITE_SIZE) && (y >= currY1 && y < currY1 + SPRITE_SIZE) && p1Health > 0;
	
    wire p2isInSquare;
    assign p2isInSquare = (x >= currX2 && x < currX2 + SPRITE_SIZE) && (y >= currY2 && y < currY2 + SPRITE_SIZE) && p2Health > 0;
	   
    // P1 LEFT
    wire P1DOWN = JD[7];
    wire P1RIGHT = JD[10];
    wire P1LEFT = JD[9];
    wire P1UP = JD[8];

	       
	// P1 RIGHT
//	wire DOWN = JD[4];
//	wire RIGHT = JD[3];
//	wire LEFT = JD[2];
//	wire UP = JD[1];

    // P2 LEFT 
    wire P2DOWN = JC[10];
    wire P2RIGHT = JC[8];
    wire P2LEFT = JC[7];
    wire P2UP = JC[9];
    
    
    // P2 RIGHT
//    wire DOWN = JC[1];
//    wire RIGHT = JC[2];
//    wire LEFT = JC[3];
//    wire UP = JC[4];

    // DEBUG JOYSTICKS
//    wire DOWN = JD[7] || JD[4] || JC[10] || JC[1];
//    wire RIGHT = JD[10] || JD[3] || JC[8] || JC[2];
//    wire LEFT = JD[9] || JD[2] || JC[7] || JC[3];
//    wire UP = JD[8] || JD[1] || JC[9] || JC[4];

	// VGA Timing Generation for a Standard VGA Screen
	localparam 
		VIDEO_WIDTH = 640,  // Standard VGA Width
		VIDEO_HEIGHT = 480, // Standard VGA Height
		SPRITE_SIZE = 64,   // Size of the sprite
		BULLET_SIZE = 12,	// Size of the bullet
        MAX_BULLETS = 64;	// Maximum number of bullets

	wire active, screenEnd;
	wire[9:0] x;
	wire[8:0] y;
	
	VGATimingGenerator #(
		.HEIGHT(VIDEO_HEIGHT), // Use the standard VGA Values
		.WIDTH(VIDEO_WIDTH))
	Display( 
		.clk25(clk),  	   // 25MHz Pixel Clock
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
	
    wire [9:0] sprite1_x = x - currX1;
    wire [8:0] sprite1_y = y - currY1;
    
    wire [SPRITE_PIXEL_ADDRESS_WIDTH-1:0] spriteAddress1 = sprite1_x + (SPRITE_SIZE * sprite1_y);				 // Address calculated active
    wire [PALETTE_ADDRESS_WIDTH-1:0] sprite1ColorAddr;
	
	VRAM #(		
		.DEPTH(SPRITE_PIXEL_COUNT), 		            // Set RAM depth to contain every pixel
		.DATA_WIDTH(PALETTE_ADDRESS_WIDTH),             // Set data width according to the color palette
		.ADDRESS_WIDTH(SPRITE_PIXEL_ADDRESS_WIDTH),     // Set address with according to the pixel count
		.MEMFILE({MEM_FILES_PATH, "p1Tankimage.mem"}))            // Memory initialization
	ImageData2(
		.clk(clk), 						         // Falling edge of the 100 MHz clk
		.addr(spriteAddress1),					 // Image data address
		.dataOut(sprite1ColorAddr),				 // Color palette address
		.wEn(1'b0)); 						     // We're always reading
	
	// Color Palette to Map Color Address to 12-Bit Color
	wire[BITS_PER_COLOR-1:0] sprite1ColorData; // 12-bit color data at current pixel
	
	VRAM #(
		.DEPTH(PALETTE_COLOR_COUNT), 		       // Set depth to contain every color		
		.DATA_WIDTH(BITS_PER_COLOR), 		       // Set data width according to the bits per color
		.ADDRESS_WIDTH(PALETTE_ADDRESS_WIDTH),     // Set address width according to the color count
		.MEMFILE({MEM_FILES_PATH, "p1Tankcolors.mem"}))  // Memory initialization
	ColorPalette2(
		.clk(clk), 							   	   // Rising edge of the 100 MHz clk
		.addr(sprite1ColorAddr),					   // Address from the ImageData RAM
		.dataOut(sprite1ColorData),				   // Color at current pixel
		.wEn(1'b0)); 						       // We're always reading
		
		
		
		
	wire [9:0] sprite2_x = x - currX2;
    wire [8:0] sprite2_y = y - currY2;
    
    wire [SPRITE_PIXEL_ADDRESS_WIDTH-1:0] spriteAddress2 = sprite2_x + (SPRITE_SIZE * sprite2_y);				 // Address calculated active
    wire [PALETTE_ADDRESS_WIDTH-1:0] sprite2ColorAddr;
	
	VRAM #(		
		.DEPTH(SPRITE_PIXEL_COUNT), 		            // Set RAM depth to contain every pixel
		.DATA_WIDTH(PALETTE_ADDRESS_WIDTH),             // Set data width according to the color palette
		.ADDRESS_WIDTH(SPRITE_PIXEL_ADDRESS_WIDTH),     // Set address with according to the pixel count
		.MEMFILE({MEM_FILES_PATH, "p2Tankimage.mem"}))            // Memory initialization
	ImageData3(
		.clk(clk), 						         // Falling edge of the 100 MHz clk
		.addr(spriteAddress2),					 // Image data address
		.dataOut(sprite2ColorAddr),				 // Color palette address
		.wEn(1'b0)); 						     // We're always reading
	
	// Color Palette to Map Color Address to 12-Bit Color
	wire[BITS_PER_COLOR-1:0] sprite2ColorData; // 12-bit color data at current pixel
	
	VRAM #(
		.DEPTH(PALETTE_COLOR_COUNT), 		       // Set depth to contain every color		
		.DATA_WIDTH(BITS_PER_COLOR), 		       // Set data width according to the bits per color
		.ADDRESS_WIDTH(PALETTE_ADDRESS_WIDTH),     // Set address width according to the color count
		.MEMFILE({MEM_FILES_PATH, "p2Tankcolors.mem"}))  // Memory initialization
	ColorPalette3(
		.clk(clk), 							   	   // Rising edge of the 100 MHz clk
		.addr(sprite2ColorAddr),					   // Address from the ImageData RAM
		.dataOut(sprite2ColorData),				   // Color at current pixel
		.wEn(1'b0)); 						       // We're always reading
	
	
	
	

	VRAM #(		
		.DEPTH(PIXEL_COUNT), 				     // Set RAM depth to contain every pixel
		.DATA_WIDTH(PALETTE_ADDRESS_WIDTH),      // Set data width according to the color palette
		.ADDRESS_WIDTH(PIXEL_ADDRESS_WIDTH),     // Set address with according to the pixel count
		.MEMFILE({MEM_FILES_PATH, "arenaMapPentimage.mem"})) // Memory initialization
	ImageData (
		.clk(clk), 						 // Falling edge of the 100 MHz clk
		.addr(imgAddress),					 // Image data address
		.dataOut(colorAddr),				 // Color palette address
		.wEn(1'b0)); 						 // We're always reading

	// Color Palette to Map Color Address to 12-Bit Color
	wire[BITS_PER_COLOR-1:0] colorData; // 12-bit color data at current pixel

	VRAM #(
		.DEPTH(PALETTE_COLOR_COUNT), 		       // Set depth to contain every color		
		.DATA_WIDTH(BITS_PER_COLOR), 		       // Set data width according to the bits per color
		.ADDRESS_WIDTH(PALETTE_ADDRESS_WIDTH),     // Set address width according to the color count
		.MEMFILE({MEM_FILES_PATH, "arenaMapPentcolors.mem"}))  // Memory initialization
	ColorPalette (
		.clk(clk), 							   	   // Rising edge of the 100 MHz clk
		.addr(colorAddr),					       // Address from the ImageData RAM
		.dataOut(colorData),				       // Color at current pixel
		.wEn(1'b0)); 						       // We're always reading
	



	// Iterate over all bullets
    reg [31:0] bulletData;
	reg [9:0] bulletX;
	reg [8:0] bulletY;
	reg activeFlag;
	reg isBulletActive;

    integer j;
	always @(*) begin
		isBulletActive = 0; // Default: no overlap
		for (j = 0; j < MAX_BULLETS; j = j + 1) begin
			// Extract bullet data
			bulletData = allBulletContents[(j*32) +: 32]; // Extract 32 bits for each bullet
			bulletX = bulletData[31:22];
			bulletY = bulletData[21:13];
			activeFlag = bulletData[2];

			// Check if current pixel overlaps with this bullet
			if (activeFlag &&
				x >= bulletX && x < bulletX + BULLET_SIZE &&
				y >= bulletY && y < bulletY + BULLET_SIZE) begin
				isBulletActive = 1; // Set active flag if there's an overlap
			end
		end
	end






	// Assign to output color from register if active
	wire[BITS_PER_COLOR-1:0] colorOut; 			  // Output color 
	wire [11:0] bulletColorData = 12'hF00; // Red color for bullets

	assign colorOut = active ? 
    	(p1isInSquare ? sprite1ColorData : 
    	p2isInSquare ? sprite2ColorData :
     	isBulletActive ? bulletColorData : colorData) : 
    	12'd0; // Black when not active

	// Quickly assign the output colors to their channels using concatenation
	assign {VGA_R, VGA_G, VGA_B} = colorOut;


endmodule