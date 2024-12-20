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
	   
	wire isInP1Health;
	assign isInP1Health = (x > 31 && x < 30 + HEALTH_WIDTH) && (y >= 30 && y < 30 + HEALTH_HEIGHT);

	wire isInP2Health;
	assign isInP2Health = (x > 511 && x < 510 + HEALTH_WIDTH) && (y >= 30 && y < 30 + HEALTH_HEIGHT);
	

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
        MAX_BULLETS = 64,	// Maximum number of bullets
		HEALTH_WIDTH = 100, // Width of the health bar
		HEALTH_HEIGHT = 50; // Height of the health bar

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
		.dataOut(sprite1ColorAddr),
		.wEn(1'b0)); 						  
	
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
		.dataOut(sprite1ColorData),
		.wEn(1'b0)); 						     
		
		
		
		
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
		.dataOut(sprite2ColorAddr),
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
		.dataOut(sprite2ColorData),
		.wEn(1'b0)); 						       // We're always reading
	
	
	
	

	VRAM #(		
		.DEPTH(PIXEL_COUNT), 				     // Set RAM depth to contain every pixel
		.DATA_WIDTH(PALETTE_ADDRESS_WIDTH),      // Set data width according to the color palette
		.ADDRESS_WIDTH(PIXEL_ADDRESS_WIDTH),     // Set address with according to the pixel count
		.MEMFILE({MEM_FILES_PATH, "arenaMapPentimage.mem"})) // Memory initialization
	ImageData (
		.clk(clk), 						 // Falling edge of the 100 MHz clk
		.addr(imgAddress),					 // Image data address
		.dataOut(colorAddr),
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
		.dataOut(colorData),
		.wEn(1'b0)); 						       // We're always reading

	// Start Screen Image 1
	// VRAM #(		
	// 	.DEPTH(PIXEL_COUNT), 				     // Set RAM depth to contain every pixel
	// 	.DATA_WIDTH(PALETTE_ADDRESS_WIDTH),      // Set data width according to the color palette
	// 	.ADDRESS_WIDTH(PIXEL_ADDRESS_WIDTH),     // Set address with according to the pixel count
	// 	.MEMFILE({MEM_FILES_PATH, "startScreen1image.mem"})) // Memory initialization
	// ImageData4 (
	// 	.clk(clk), 						 // Falling edge of the 100 MHz clk
	// 	.addr(startScreen1imgAddress),					 // Image data address
	// 	.dataOut(startScreen1colorAddr));				 // Color palette address); 		

	// wire[BITS_PER_COLOR-1:0] startScreen1colorData; // 12-bit color data at current pixel
	// wire[PIXEL_ADDRESS_WIDTH-1:0] startScreen1imgAddress;  	 // Image address for the image data
	// wire[PALETTE_ADDRESS_WIDTH-1:0] startScreen1colorAddr; 	 // Color address for the color palette
	// assign startScreen1imgAddress = x + 640*y;				 // Address calculated coordinate

	// VRAM #(
	// 	.DEPTH(PALETTE_COLOR_COUNT), 		       // Set depth to contain every color		
	// 	.DATA_WIDTH(BITS_PER_COLOR), 		       // Set data width according to the bits per color
	// 	.ADDRESS_WIDTH(PALETTE_ADDRESS_WIDTH),     // Set address width according to the color count
	// 	.MEMFILE({MEM_FILES_PATH, "startScreen1colors.mem"}))  // Memory initialization
	// ColorPalette4 (
	// 	.clk(clk), 							   	   // Rising edge of the 100 MHz clk
	// 	.addr(startScreen1colorAddr),					       // Address from the ImageData RAM
	// 	.dataOut(startScreen1colorData)); 						      

	



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






	// Image Data to Map Pixel Location to Color Address
	localparam 
		HEALTH_PIXEL_COUNT =  100 * 50, 	             // Number of pixels on the screen
		HEALTH_PIXEL_ADDRESS_WIDTH = $clog2(HEALTH_PIXEL_COUNT) + 1;     // Use built in log2 command
	
    wire [9:0] p1_health1_x = x - 30;
    wire [8:0] p1_health1_y = y - 30;

	wire[HEALTH_PIXEL_ADDRESS_WIDTH-1:0] p1_health_imgAddress;  	 // Image address for the image data
	wire[PALETTE_ADDRESS_WIDTH-1:0] p1_health100_colorAddr; 	 // Color address for the color palette
	assign p1_health_imgAddress = p1_health1_x + HEALTH_WIDTH*p1_health1_y;				 // Address calculated coordinate
	
	VRAM #(		
		.DEPTH(HEALTH_PIXEL_COUNT), 		            // Set RAM depth to contain every pixel
		.DATA_WIDTH(PALETTE_ADDRESS_WIDTH),             // Set data width according to the color palette
		.ADDRESS_WIDTH(HEALTH_PIXEL_ADDRESS_WIDTH),     // Set address with according to the pixel count
		.MEMFILE({MEM_FILES_PATH, "health/health_mem/health_100image.mem"}))            // Memory initialization
	ImageData10(
		.clk(clk), 						         // Falling edge of the 100 MHz clk
		.addr(p1_health_imgAddress),					 // Image data address
		.dataOut(p1_health100_colorAddr),
		.wEn(1'b0)); 						  
	
	// Color Palette to Map Color Address to 12-Bit Color
	wire[BITS_PER_COLOR-1:0] p1_health100_ColorData; // 12-bit color data at current pixel
	
	VRAM #(
		.DEPTH(PALETTE_COLOR_COUNT), 		       // Set depth to contain every color		
		.DATA_WIDTH(BITS_PER_COLOR), 		       // Set data width according to the bits per color
		.ADDRESS_WIDTH(PALETTE_ADDRESS_WIDTH),     // Set address width according to the color count
		.MEMFILE({MEM_FILES_PATH, "health/health_mem/health_100colors.mem"}))  // Memory initialization
	ColorPalette10(
		.clk(clk), 							   	   // Rising edge of the 100 MHz clk
		.addr(p1_health100_colorAddr),					   // Address from the ImageData RAM
		.dataOut(p1_health100_ColorData),
		.wEn(1'b0)); 						     


	wire[PALETTE_ADDRESS_WIDTH-1:0] p1_health95_colorAddr; 	 // Color address for the color palette
	VRAM #(		
		.DEPTH(HEALTH_PIXEL_COUNT), 		            // Set RAM depth to contain every pixel
		.DATA_WIDTH(PALETTE_ADDRESS_WIDTH),             // Set data width according to the color palette
		.ADDRESS_WIDTH(HEALTH_PIXEL_ADDRESS_WIDTH),     // Set address with according to the pixel count
		.MEMFILE({MEM_FILES_PATH, "health/health_mem/health_95image.mem"}))            // Memory initialization
	ImageData11(
		.clk(clk), 						         // Falling edge of the 100 MHz clk
		.addr(p1_health_imgAddress),					 // Image data address
		.dataOut(p1_health95_colorAddr),
		.wEn(1'b0)); 						  
	
	// Color Palette to Map Color Address to 12-Bit Color
	wire[BITS_PER_COLOR-1:0] p1_health95_ColorData; // 12-bit color data at current pixel
	
	VRAM #(
		.DEPTH(PALETTE_COLOR_COUNT), 		       // Set depth to contain every color		
		.DATA_WIDTH(BITS_PER_COLOR), 		       // Set data width according to the bits per color
		.ADDRESS_WIDTH(PALETTE_ADDRESS_WIDTH),     // Set address width according to the color count
		.MEMFILE({MEM_FILES_PATH, "health/health_mem/health_95colors.mem"}))  // Memory initialization
	ColorPalette11(
		.clk(clk), 							   	   // Rising edge of the 100 MHz clk
		.addr(p1_health95_colorAddr),					   // Address from the ImageData RAM
		.dataOut(p1_health95_ColorData),
		.wEn(1'b0)); 				





	wire[PALETTE_ADDRESS_WIDTH-1:0] p1_health90_colorAddr; 	 // Color address for the color palette
	VRAM #(		
		.DEPTH(HEALTH_PIXEL_COUNT), 		            // Set RAM depth to contain every pixel
		.DATA_WIDTH(PALETTE_ADDRESS_WIDTH),             // Set data width according to the color palette
		.ADDRESS_WIDTH(HEALTH_PIXEL_ADDRESS_WIDTH),     // Set address with according to the pixel count
		.MEMFILE({MEM_FILES_PATH, "health/health_mem/health_90image.mem"}))            // Memory initialization
	ImageData12(
		.clk(clk), 						         // Falling edge of the 100 MHz clk
		.addr(p1_health_imgAddress),					 // Image data address
		.dataOut(p1_health90_colorAddr),
		.wEn(1'b0)); 						  
	
	// Color Palette to Map Color Address to 12-Bit Color
	wire[BITS_PER_COLOR-1:0] p1_health90_ColorData; // 12-bit color data at current pixel
	
	VRAM #(
		.DEPTH(PALETTE_COLOR_COUNT), 		       // Set depth to contain every color		
		.DATA_WIDTH(BITS_PER_COLOR), 		       // Set data width according to the bits per color
		.ADDRESS_WIDTH(PALETTE_ADDRESS_WIDTH),     // Set address width according to the color count
		.MEMFILE({MEM_FILES_PATH, "health/health_mem/health_90colors.mem"}))  // Memory initialization
	ColorPalette12(
		.clk(clk), 							   	   // Rising edge of the 100 MHz clk
		.addr(p1_health90_colorAddr),					   // Address from the ImageData RAM
		.dataOut(p1_health90_ColorData),
		.wEn(1'b0));		     

	
	wire[PALETTE_ADDRESS_WIDTH-1:0] p1_health85_colorAddr; 	 // Color address for the color palette
	VRAM #(		
		.DEPTH(HEALTH_PIXEL_COUNT), 		            // Set RAM depth to contain every pixel
		.DATA_WIDTH(PALETTE_ADDRESS_WIDTH),             // Set data width according to the color palette
		.ADDRESS_WIDTH(HEALTH_PIXEL_ADDRESS_WIDTH),     // Set address with according to the pixel count
		.MEMFILE({MEM_FILES_PATH, "health/health_mem/health_85image.mem"}))            // Memory initialization
	ImageData13(
		.clk(clk), 						         // Falling edge of the 100 MHz clk
		.addr(p1_health_imgAddress),					 // Image data address
		.dataOut(p1_health85_colorAddr),
		.wEn(1'b0)); 						  
	
	// Color Palette to Map Color Address to 12-Bit Color
	wire[BITS_PER_COLOR-1:0] p1_health85_ColorData; // 12-bit color data at current pixel
	
	VRAM #(
		.DEPTH(PALETTE_COLOR_COUNT), 		       // Set depth to contain every color		
		.DATA_WIDTH(BITS_PER_COLOR), 		       // Set data width according to the bits per color
		.ADDRESS_WIDTH(PALETTE_ADDRESS_WIDTH),     // Set address width according to the color count
		.MEMFILE({MEM_FILES_PATH, "health/health_mem/health_85colors.mem"}))  // Memory initialization
	ColorPalette13(
		.clk(clk), 							   	   // Rising edge of the 100 MHz clk
		.addr(p1_health85_colorAddr),					   // Address from the ImageData RAM
		.dataOut(p1_health85_ColorData),
		.wEn(1'b0));

	
	wire[PALETTE_ADDRESS_WIDTH-1:0] p1_health80_colorAddr; 	 // Color address for the color palette
	VRAM #(		
		.DEPTH(HEALTH_PIXEL_COUNT), 		            // Set RAM depth to contain every pixel
		.DATA_WIDTH(PALETTE_ADDRESS_WIDTH),             // Set data width according to the color palette
		.ADDRESS_WIDTH(HEALTH_PIXEL_ADDRESS_WIDTH),     // Set address with according to the pixel count
		.MEMFILE({MEM_FILES_PATH, "health/health_mem/health_80image.mem"}))            // Memory initialization
	ImageData14(
		.clk(clk), 						         // Falling edge of the 100 MHz clk
		.addr(p1_health_imgAddress),					 // Image data address
		.dataOut(p1_health80_colorAddr),
		.wEn(1'b0)); 						  
	
	// Color Palette to Map Color Address to 12-Bit Color
	wire[BITS_PER_COLOR-1:0] p1_health80_ColorData; // 12-bit color data at current pixel
	
	VRAM #(
		.DEPTH(PALETTE_COLOR_COUNT), 		       // Set depth to contain every color		
		.DATA_WIDTH(BITS_PER_COLOR), 		       // Set data width according to the bits per color
		.ADDRESS_WIDTH(PALETTE_ADDRESS_WIDTH),     // Set address width according to the color count
		.MEMFILE({MEM_FILES_PATH, "health/health_mem/health_80colors.mem"}))  // Memory initialization
	ColorPalette14(
		.clk(clk), 							   	   // Rising edge of the 100 MHz clk
		.addr(p1_health80_colorAddr),					   // Address from the ImageData RAM
		.dataOut(p1_health80_ColorData),
		.wEn(1'b0));


	wire[PALETTE_ADDRESS_WIDTH-1:0] p1_health75_colorAddr; 	 // Color address for the color palette
	VRAM #(		
		.DEPTH(HEALTH_PIXEL_COUNT), 		            // Set RAM depth to contain every pixel
		.DATA_WIDTH(PALETTE_ADDRESS_WIDTH),             // Set data width according to the color palette
		.ADDRESS_WIDTH(HEALTH_PIXEL_ADDRESS_WIDTH),     // Set address with according to the pixel count
		.MEMFILE({MEM_FILES_PATH, "health/health_mem/health_75image.mem"}))            // Memory initialization
	ImageData15(
		.clk(clk), 						         // Falling edge of the 100 MHz clk
		.addr(p1_health_imgAddress),					 // Image data address
		.dataOut(p1_health75_colorAddr),
		.wEn(1'b0)); 						  
	
	// Color Palette to Map Color Address to 12-Bit Color
	wire[BITS_PER_COLOR-1:0] p1_health75_ColorData; // 12-bit color data at current pixel
	
	VRAM #(
		.DEPTH(PALETTE_COLOR_COUNT), 		       // Set depth to contain every color		
		.DATA_WIDTH(BITS_PER_COLOR), 		       // Set data width according to the bits per color
		.ADDRESS_WIDTH(PALETTE_ADDRESS_WIDTH),     // Set address width according to the color count
		.MEMFILE({MEM_FILES_PATH, "health/health_mem/health_75colors.mem"}))  // Memory initialization
	ColorPalette15(
		.clk(clk), 							   	   // Rising edge of the 100 MHz clk
		.addr(p1_health75_colorAddr),					   // Address from the ImageData RAM
		.dataOut(p1_health75_ColorData),
		.wEn(1'b0));

	
	wire[PALETTE_ADDRESS_WIDTH-1:0] p1_health70_colorAddr; 	 // Color address for the color palette
	VRAM #(		
		.DEPTH(HEALTH_PIXEL_COUNT), 		            // Set RAM depth to contain every pixel
		.DATA_WIDTH(PALETTE_ADDRESS_WIDTH),             // Set data width according to the color palette
		.ADDRESS_WIDTH(HEALTH_PIXEL_ADDRESS_WIDTH),     // Set address with according to the pixel count
		.MEMFILE({MEM_FILES_PATH, "health/health_mem/health_70image.mem"}))            // Memory initialization
	ImageData16(
		.clk(clk), 						         // Falling edge of the 100 MHz clk
		.addr(p1_health_imgAddress),					 // Image data address
		.dataOut(p1_health70_colorAddr),
		.wEn(1'b0)); 						  
	
	// Color Palette to Map Color Address to 12-Bit Color
	wire[BITS_PER_COLOR-1:0] p1_health70_ColorData; // 12-bit color data at current pixel
	
	VRAM #(
		.DEPTH(PALETTE_COLOR_COUNT), 		       // Set depth to contain every color		
		.DATA_WIDTH(BITS_PER_COLOR), 		       // Set data width according to the bits per color
		.ADDRESS_WIDTH(PALETTE_ADDRESS_WIDTH),     // Set address width according to the color count
		.MEMFILE({MEM_FILES_PATH, "health/health_mem/health_70colors.mem"}))  // Memory initialization
	ColorPalette16(
		.clk(clk), 							   	   // Rising edge of the 100 MHz clk
		.addr(p1_health70_colorAddr),					   // Address from the ImageData RAM
		.dataOut(p1_health70_ColorData),
		.wEn(1'b0));

	
	wire[PALETTE_ADDRESS_WIDTH-1:0] p1_health65_colorAddr; 	 // Color address for the color palette
	VRAM #(		
		.DEPTH(HEALTH_PIXEL_COUNT), 		            // Set RAM depth to contain every pixel
		.DATA_WIDTH(PALETTE_ADDRESS_WIDTH),             // Set data width according to the color palette
		.ADDRESS_WIDTH(HEALTH_PIXEL_ADDRESS_WIDTH),     // Set address with according to the pixel count
		.MEMFILE({MEM_FILES_PATH, "health/health_mem/health_65image.mem"}))            // Memory initialization
	ImageData17(
		.clk(clk), 						         // Falling edge of the 100 MHz clk
		.addr(p1_health_imgAddress),					 // Image data address
		.dataOut(p1_health65_colorAddr),
		.wEn(1'b0)); 						  
	
	// Color Palette to Map Color Address to 12-Bit Color
	wire[BITS_PER_COLOR-1:0] p1_health65_ColorData; // 12-bit color data at current pixel
	
	VRAM #(
		.DEPTH(PALETTE_COLOR_COUNT), 		       // Set depth to contain every color		
		.DATA_WIDTH(BITS_PER_COLOR), 		       // Set data width according to the bits per color
		.ADDRESS_WIDTH(PALETTE_ADDRESS_WIDTH),     // Set address width according to the color count
		.MEMFILE({MEM_FILES_PATH, "health/health_mem/health_65colors.mem"}))  // Memory initialization
	ColorPalette17(
		.clk(clk), 							   	   // Rising edge of the 100 MHz clk
		.addr(p1_health65_colorAddr),					   // Address from the ImageData RAM
		.dataOut(p1_health65_ColorData),
		.wEn(1'b0));


	wire[PALETTE_ADDRESS_WIDTH-1:0] p1_health60_colorAddr; 	 // Color address for the color palette
	VRAM #(		
		.DEPTH(HEALTH_PIXEL_COUNT), 		            // Set RAM depth to contain every pixel
		.DATA_WIDTH(PALETTE_ADDRESS_WIDTH),             // Set data width according to the color palette
		.ADDRESS_WIDTH(HEALTH_PIXEL_ADDRESS_WIDTH),     // Set address with according to the pixel count
		.MEMFILE({MEM_FILES_PATH, "health/health_mem/health_60image.mem"}))            // Memory initialization
	ImageData18(
		.clk(clk), 						         // Falling edge of the 100 MHz clk
		.addr(p1_health_imgAddress),					 // Image data address
		.dataOut(p1_health60_colorAddr),
		.wEn(1'b0)); 						  
	
	// Color Palette to Map Color Address to 12-Bit Color
	wire[BITS_PER_COLOR-1:0] p1_health60_ColorData; // 12-bit color data at current pixel
	
	VRAM #(
		.DEPTH(PALETTE_COLOR_COUNT), 		       // Set depth to contain every color		
		.DATA_WIDTH(BITS_PER_COLOR), 		       // Set data width according to the bits per color
		.ADDRESS_WIDTH(PALETTE_ADDRESS_WIDTH),     // Set address width according to the color count
		.MEMFILE({MEM_FILES_PATH, "health/health_mem/health_60colors.mem"}))  // Memory initialization
	ColorPalette18(
		.clk(clk), 							   	   // Rising edge of the 100 MHz clk
		.addr(p1_health60_colorAddr),					   // Address from the ImageData RAM
		.dataOut(p1_health60_ColorData),
		.wEn(1'b0));

	wire[PALETTE_ADDRESS_WIDTH-1:0] p1_health55_colorAddr; 	 // Color address for the color palette
	VRAM #(		
		.DEPTH(HEALTH_PIXEL_COUNT), 		            // Set RAM depth to contain every pixel
		.DATA_WIDTH(PALETTE_ADDRESS_WIDTH),             // Set data width according to the color palette
		.ADDRESS_WIDTH(HEALTH_PIXEL_ADDRESS_WIDTH),     // Set address with according to the pixel count
		.MEMFILE({MEM_FILES_PATH, "health/health_mem/health_55image.mem"}))            // Memory initialization
	ImageData19(
		.clk(clk), 						         // Falling edge of the 100 MHz clk
		.addr(p1_health_imgAddress),					 // Image data address
		.dataOut(p1_health55_colorAddr),
		.wEn(1'b0)); 						  
	
	// Color Palette to Map Color Address to 12-Bit Color
	wire[BITS_PER_COLOR-1:0] p1_health55_ColorData; // 12-bit color data at current pixel
	
	VRAM #(
		.DEPTH(PALETTE_COLOR_COUNT), 		       // Set depth to contain every color		
		.DATA_WIDTH(BITS_PER_COLOR), 		       // Set data width according to the bits per color
		.ADDRESS_WIDTH(PALETTE_ADDRESS_WIDTH),     // Set address width according to the color count
		.MEMFILE({MEM_FILES_PATH, "health/health_mem/health_55colors.mem"}))  // Memory initialization
	ColorPalette19(
		.clk(clk), 							   	   // Rising edge of the 100 MHz clk
		.addr(p1_health55_colorAddr),					   // Address from the ImageData RAM
		.dataOut(p1_health55_ColorData),
		.wEn(1'b0));

	
	wire[PALETTE_ADDRESS_WIDTH-1:0] p1_health50_colorAddr; 	 // Color address for the color palette
	VRAM #(		
		.DEPTH(HEALTH_PIXEL_COUNT), 		            // Set RAM depth to contain every pixel
		.DATA_WIDTH(PALETTE_ADDRESS_WIDTH),             // Set data width according to the color palette
		.ADDRESS_WIDTH(HEALTH_PIXEL_ADDRESS_WIDTH),     // Set address with according to the pixel count
		.MEMFILE({MEM_FILES_PATH, "health/health_mem/health_50image.mem"}))            // Memory initialization
	ImageData20(
		.clk(clk), 						         // Falling edge of the 100 MHz clk
		.addr(p1_health_imgAddress),					 // Image data address
		.dataOut(p1_health50_colorAddr),
		.wEn(1'b0)); 						  
	
	// Color Palette to Map Color Address to 12-Bit Color
	wire[BITS_PER_COLOR-1:0] p1_health50_ColorData; // 12-bit color data at current pixel
	
	VRAM #(
		.DEPTH(PALETTE_COLOR_COUNT), 		       // Set depth to contain every color		
		.DATA_WIDTH(BITS_PER_COLOR), 		       // Set data width according to the bits per color
		.ADDRESS_WIDTH(PALETTE_ADDRESS_WIDTH),     // Set address width according to the color count
		.MEMFILE({MEM_FILES_PATH, "health/health_mem/health_50colors.mem"}))  // Memory initialization
	ColorPalette20(
		.clk(clk), 							   	   // Rising edge of the 100 MHz clk
		.addr(p1_health50_colorAddr),					   // Address from the ImageData RAM
		.dataOut(p1_health50_ColorData),
		.wEn(1'b0));


	wire[PALETTE_ADDRESS_WIDTH-1:0] p1_health45_colorAddr; 	 // Color address for the color palette
	VRAM #(		
		.DEPTH(HEALTH_PIXEL_COUNT), 		            // Set RAM depth to contain every pixel
		.DATA_WIDTH(PALETTE_ADDRESS_WIDTH),             // Set data width according to the color palette
		.ADDRESS_WIDTH(HEALTH_PIXEL_ADDRESS_WIDTH),     // Set address with according to the pixel count
		.MEMFILE({MEM_FILES_PATH, "health/health_mem/health_45image.mem"}))            // Memory initialization
	ImageData21(
		.clk(clk), 						         // Falling edge of the 100 MHz clk
		.addr(p1_health_imgAddress),					 // Image data address
		.dataOut(p1_health45_colorAddr),
		.wEn(1'b0)); 						  
	
	// Color Palette to Map Color Address to 12-Bit Color
	wire[BITS_PER_COLOR-1:0] p1_health45_ColorData; // 12-bit color data at current pixel
	
	VRAM #(
		.DEPTH(PALETTE_COLOR_COUNT), 		       // Set depth to contain every color		
		.DATA_WIDTH(BITS_PER_COLOR), 		       // Set data width according to the bits per color
		.ADDRESS_WIDTH(PALETTE_ADDRESS_WIDTH),     // Set address width according to the color count
		.MEMFILE({MEM_FILES_PATH, "health/health_mem/health_45colors.mem"}))  // Memory initialization
	ColorPalette21(
		.clk(clk), 							   	   // Rising edge of the 100 MHz clk
		.addr(p1_health45_colorAddr),					   // Address from the ImageData RAM
		.dataOut(p1_health45_ColorData),
		.wEn(1'b0));


	wire[PALETTE_ADDRESS_WIDTH-1:0] p1_health40_colorAddr; 	 // Color address for the color palette
	VRAM #(		
		.DEPTH(HEALTH_PIXEL_COUNT), 		            // Set RAM depth to contain every pixel
		.DATA_WIDTH(PALETTE_ADDRESS_WIDTH),             // Set data width according to the color palette
		.ADDRESS_WIDTH(HEALTH_PIXEL_ADDRESS_WIDTH),     // Set address with according to the pixel count
		.MEMFILE({MEM_FILES_PATH, "health/health_mem/health_40image.mem"}))            // Memory initialization
	ImageData22(
		.clk(clk), 						         // Falling edge of the 100 MHz clk
		.addr(p1_health_imgAddress),					 // Image data address
		.dataOut(p1_health40_colorAddr),
		.wEn(1'b0)); 						  
	
	// Color Palette to Map Color Address to 12-Bit Color
	wire[BITS_PER_COLOR-1:0] p1_health40_ColorData; // 12-bit color data at current pixel
	
	VRAM #(
		.DEPTH(PALETTE_COLOR_COUNT), 		       // Set depth to contain every color		
		.DATA_WIDTH(BITS_PER_COLOR), 		       // Set data width according to the bits per color
		.ADDRESS_WIDTH(PALETTE_ADDRESS_WIDTH),     // Set address width according to the color count
		.MEMFILE({MEM_FILES_PATH, "health/health_mem/health_40colors.mem"}))  // Memory initialization
	ColorPalette22(
		.clk(clk), 							   	   // Rising edge of the 100 MHz clk
		.addr(p1_health40_colorAddr),					   // Address from the ImageData RAM
		.dataOut(p1_health40_ColorData),
		.wEn(1'b0));


	wire[PALETTE_ADDRESS_WIDTH-1:0] p1_health35_colorAddr; 	 // Color address for the color palette
	VRAM #(		
		.DEPTH(HEALTH_PIXEL_COUNT), 		            // Set RAM depth to contain every pixel
		.DATA_WIDTH(PALETTE_ADDRESS_WIDTH),             // Set data width according to the color palette
		.ADDRESS_WIDTH(HEALTH_PIXEL_ADDRESS_WIDTH),     // Set address with according to the pixel count
		.MEMFILE({MEM_FILES_PATH, "health/health_mem/health_35image.mem"}))            // Memory initialization
	ImageData23(
		.clk(clk), 						         // Falling edge of the 100 MHz clk
		.addr(p1_health_imgAddress),					 // Image data address
		.dataOut(p1_health35_colorAddr),
		.wEn(1'b0)); 						  
	
	// Color Palette to Map Color Address to 12-Bit Color
	wire[BITS_PER_COLOR-1:0] p1_health35_ColorData; // 12-bit color data at current pixel
	
	VRAM #(
		.DEPTH(PALETTE_COLOR_COUNT), 		       // Set depth to contain every color		
		.DATA_WIDTH(BITS_PER_COLOR), 		       // Set data width according to the bits per color
		.ADDRESS_WIDTH(PALETTE_ADDRESS_WIDTH),     // Set address width according to the color count
		.MEMFILE({MEM_FILES_PATH, "health/health_mem/health_35colors.mem"}))  // Memory initialization
	ColorPalette23(
		.clk(clk), 							   	   // Rising edge of the 100 MHz clk
		.addr(p1_health35_colorAddr),					   // Address from the ImageData RAM
		.dataOut(p1_health35_ColorData),
		.wEn(1'b0));


	wire[PALETTE_ADDRESS_WIDTH-1:0] p1_health30_colorAddr; 	 // Color address for the color palette
	VRAM #(		
		.DEPTH(HEALTH_PIXEL_COUNT), 		            // Set RAM depth to contain every pixel
		.DATA_WIDTH(PALETTE_ADDRESS_WIDTH),             // Set data width according to the color palette
		.ADDRESS_WIDTH(HEALTH_PIXEL_ADDRESS_WIDTH),     // Set address with according to the pixel count
		.MEMFILE({MEM_FILES_PATH, "health/health_mem/health_30image.mem"}))            // Memory initialization
	ImageData24(
		.clk(clk), 						         // Falling edge of the 100 MHz clk
		.addr(p1_health_imgAddress),					 // Image data address
		.dataOut(p1_health30_colorAddr),
		.wEn(1'b0)); 						  
	
	// Color Palette to Map Color Address to 12-Bit Color
	wire[BITS_PER_COLOR-1:0] p1_health30_ColorData; // 12-bit color data at current pixel
	
	VRAM #(
		.DEPTH(PALETTE_COLOR_COUNT), 		       // Set depth to contain every color		
		.DATA_WIDTH(BITS_PER_COLOR), 		       // Set data width according to the bits per color
		.ADDRESS_WIDTH(PALETTE_ADDRESS_WIDTH),     // Set address width according to the color count
		.MEMFILE({MEM_FILES_PATH, "health/health_mem/health_30colors.mem"}))  // Memory initialization
	ColorPalette24(
		.clk(clk), 							   	   // Rising edge of the 100 MHz clk
		.addr(p1_health30_colorAddr),					   // Address from the ImageData RAM
		.dataOut(p1_health30_ColorData),
		.wEn(1'b0));


	wire[PALETTE_ADDRESS_WIDTH-1:0] p1_health25_colorAddr; 	 // Color address for the color palette
	VRAM #(		
		.DEPTH(HEALTH_PIXEL_COUNT), 		            // Set RAM depth to contain every pixel
		.DATA_WIDTH(PALETTE_ADDRESS_WIDTH),             // Set data width according to the color palette
		.ADDRESS_WIDTH(HEALTH_PIXEL_ADDRESS_WIDTH),     // Set address with according to the pixel count
		.MEMFILE({MEM_FILES_PATH, "health/health_mem/health_25image.mem"}))            // Memory initialization
	ImageData25(
		.clk(clk), 						         // Falling edge of the 100 MHz clk
		.addr(p1_health_imgAddress),					 // Image data address
		.dataOut(p1_health25_colorAddr),
		.wEn(1'b0)); 						  
	
	// Color Palette to Map Color Address to 12-Bit Color
	wire[BITS_PER_COLOR-1:0] p1_health25_ColorData; // 12-bit color data at current pixel
	
	VRAM #(
		.DEPTH(PALETTE_COLOR_COUNT), 		       // Set depth to contain every color		
		.DATA_WIDTH(BITS_PER_COLOR), 		       // Set data width according to the bits per color
		.ADDRESS_WIDTH(PALETTE_ADDRESS_WIDTH),     // Set address width according to the color count
		.MEMFILE({MEM_FILES_PATH, "health/health_mem/health_25colors.mem"}))  // Memory initialization
	ColorPalette25(
		.clk(clk), 							   	   // Rising edge of the 100 MHz clk
		.addr(p1_health25_colorAddr),					   // Address from the ImageData RAM
		.dataOut(p1_health25_ColorData),
		.wEn(1'b0));

	
	wire[PALETTE_ADDRESS_WIDTH-1:0] p1_health20_colorAddr; 	 // Color address for the color palette
	VRAM #(		
		.DEPTH(HEALTH_PIXEL_COUNT), 		            // Set RAM depth to contain every pixel
		.DATA_WIDTH(PALETTE_ADDRESS_WIDTH),             // Set data width according to the color palette
		.ADDRESS_WIDTH(HEALTH_PIXEL_ADDRESS_WIDTH),     // Set address with according to the pixel count
		.MEMFILE({MEM_FILES_PATH, "health/health_mem/health_20image.mem"}))            // Memory initialization
	ImageData26(
		.clk(clk), 						         // Falling edge of the 100 MHz clk
		.addr(p1_health_imgAddress),					 // Image data address
		.dataOut(p1_health20_colorAddr),
		.wEn(1'b0)); 						  
	
	// Color Palette to Map Color Address to 12-Bit Color
	wire[BITS_PER_COLOR-1:0] p1_health20_ColorData; // 12-bit color data at current pixel
	
	VRAM #(
		.DEPTH(PALETTE_COLOR_COUNT), 		       // Set depth to contain every color		
		.DATA_WIDTH(BITS_PER_COLOR), 		       // Set data width according to the bits per color
		.ADDRESS_WIDTH(PALETTE_ADDRESS_WIDTH),     // Set address width according to the color count
		.MEMFILE({MEM_FILES_PATH, "health/health_mem/health_20colors.mem"}))  // Memory initialization
	ColorPalette26(
		.clk(clk), 							   	   // Rising edge of the 100 MHz clk
		.addr(p1_health20_colorAddr),					   // Address from the ImageData RAM
		.dataOut(p1_health20_ColorData),
		.wEn(1'b0));


	wire[PALETTE_ADDRESS_WIDTH-1:0] p1_health15_colorAddr; 	 // Color address for the color palette
	VRAM #(		
		.DEPTH(HEALTH_PIXEL_COUNT), 		            // Set RAM depth to contain every pixel
		.DATA_WIDTH(PALETTE_ADDRESS_WIDTH),             // Set data width according to the color palette
		.ADDRESS_WIDTH(HEALTH_PIXEL_ADDRESS_WIDTH),     // Set address with according to the pixel count
		.MEMFILE({MEM_FILES_PATH, "health/health_mem/health_15image.mem"}))            // Memory initialization
	ImageData27(
		.clk(clk), 						         // Falling edge of the 100 MHz clk
		.addr(p1_health_imgAddress),					 // Image data address
		.dataOut(p1_health15_colorAddr),
		.wEn(1'b0)); 						  
	
	// Color Palette to Map Color Address to 12-Bit Color
	wire[BITS_PER_COLOR-1:0] p1_health15_ColorData; // 12-bit color data at current pixel
	
	VRAM #(
		.DEPTH(PALETTE_COLOR_COUNT), 		       // Set depth to contain every color		
		.DATA_WIDTH(BITS_PER_COLOR), 		       // Set data width according to the bits per color
		.ADDRESS_WIDTH(PALETTE_ADDRESS_WIDTH),     // Set address width according to the color count
		.MEMFILE({MEM_FILES_PATH, "health/health_mem/health_15colors.mem"}))  // Memory initialization
	ColorPalette27(
		.clk(clk), 							   	   // Rising edge of the 100 MHz clk
		.addr(p1_health15_colorAddr),					   // Address from the ImageData RAM
		.dataOut(p1_health15_ColorData),
		.wEn(1'b0));

	
	wire[PALETTE_ADDRESS_WIDTH-1:0] p1_health10_colorAddr; 	 // Color address for the color palette
	VRAM #(		
		.DEPTH(HEALTH_PIXEL_COUNT), 		            // Set RAM depth to contain every pixel
		.DATA_WIDTH(PALETTE_ADDRESS_WIDTH),             // Set data width according to the color palette
		.ADDRESS_WIDTH(HEALTH_PIXEL_ADDRESS_WIDTH),     // Set address with according to the pixel count
		.MEMFILE({MEM_FILES_PATH, "health/health_mem/health_10image.mem"}))            // Memory initialization
	ImageData28(
		.clk(clk), 						         // Falling edge of the 100 MHz clk
		.addr(p1_health_imgAddress),					 // Image data address
		.dataOut(p1_health10_colorAddr),
		.wEn(1'b0)); 						  
	
	// Color Palette to Map Color Address to 12-Bit Color
	wire[BITS_PER_COLOR-1:0] p1_health10_ColorData; // 12-bit color data at current pixel
	
	VRAM #(
		.DEPTH(PALETTE_COLOR_COUNT), 		       // Set depth to contain every color		
		.DATA_WIDTH(BITS_PER_COLOR), 		       // Set data width according to the bits per color
		.ADDRESS_WIDTH(PALETTE_ADDRESS_WIDTH),     // Set address width according to the color count
		.MEMFILE({MEM_FILES_PATH, "health/health_mem/health_10colors.mem"}))  // Memory initialization
	ColorPalette28(
		.clk(clk), 							   	   // Rising edge of the 100 MHz clk
		.addr(p1_health10_colorAddr),					   // Address from the ImageData RAM
		.dataOut(p1_health10_ColorData),
		.wEn(1'b0));


	wire[PALETTE_ADDRESS_WIDTH-1:0] p1_health5_colorAddr; 	 // Color address for the color palette
	VRAM #(		
		.DEPTH(HEALTH_PIXEL_COUNT), 		            // Set RAM depth to contain every pixel
		.DATA_WIDTH(PALETTE_ADDRESS_WIDTH),             // Set data width according to the color palette
		.ADDRESS_WIDTH(HEALTH_PIXEL_ADDRESS_WIDTH),     // Set address with according to the pixel count
		.MEMFILE({MEM_FILES_PATH, "health/health_mem/health_5image.mem"}))            // Memory initialization
	ImageData29(
		.clk(clk), 						         // Falling edge of the 100 MHz clk
		.addr(p1_health_imgAddress),					 // Image data address
		.dataOut(p1_health5_colorAddr),
		.wEn(1'b0)); 						  
	
	// Color Palette to Map Color Address to 12-Bit Color
	wire[BITS_PER_COLOR-1:0] p1_health5_ColorData; // 12-bit color data at current pixel
	
	VRAM #(
		.DEPTH(PALETTE_COLOR_COUNT), 		       // Set depth to contain every color		
		.DATA_WIDTH(BITS_PER_COLOR), 		       // Set data width according to the bits per color
		.ADDRESS_WIDTH(PALETTE_ADDRESS_WIDTH),     // Set address width according to the color count
		.MEMFILE({MEM_FILES_PATH, "health/health_mem/health_5colors.mem"}))  // Memory initialization
	ColorPalette29(
		.clk(clk), 							   	   // Rising edge of the 100 MHz clk
		.addr(p1_health5_colorAddr),					   // Address from the ImageData RAM
		.dataOut(p1_health5_ColorData),
		.wEn(1'b0));


	wire[PALETTE_ADDRESS_WIDTH-1:0] p1_health0_colorAddr; 	 // Color address for the color palette
	VRAM #(		
		.DEPTH(HEALTH_PIXEL_COUNT), 		            // Set RAM depth to contain every pixel
		.DATA_WIDTH(PALETTE_ADDRESS_WIDTH),             // Set data width according to the color palette
		.ADDRESS_WIDTH(HEALTH_PIXEL_ADDRESS_WIDTH),     // Set address with according to the pixel count
		.MEMFILE({MEM_FILES_PATH, "health/health_mem/health_0image.mem"}))            // Memory initialization
	ImageData30(
		.clk(clk), 						         // Falling edge of the 100 MHz clk
		.addr(p1_health_imgAddress),					 // Image data address
		.dataOut(p1_health0_colorAddr),
		.wEn(1'b0)); 						  
	
	// Color Palette to Map Color Address to 12-Bit Color
	wire[BITS_PER_COLOR-1:0] p1_health0_ColorData; // 12-bit color data at current pixel
	
	VRAM #(
		.DEPTH(PALETTE_COLOR_COUNT), 		       // Set depth to contain every color		
		.DATA_WIDTH(BITS_PER_COLOR), 		       // Set data width according to the bits per color
		.ADDRESS_WIDTH(PALETTE_ADDRESS_WIDTH),     // Set address width according to the color count
		.MEMFILE({MEM_FILES_PATH, "health/health_mem/health_0colors.mem"}))  // Memory initialization
	ColorPalette30(
		.clk(clk), 							   	   // Rising edge of the 100 MHz clk
		.addr(p1_health0_colorAddr),					   // Address from the ImageData RAM
		.dataOut(p1_health0_ColorData),
		.wEn(1'b0));

	

	
	


	wire [9:0] p2_health1_x = x - 510;
    wire [8:0] p2_health1_y = y - 30;

	wire[HEALTH_PIXEL_ADDRESS_WIDTH-1:0] p2_health_imgAddress;  	 // Image address for the image data
	wire[PALETTE_ADDRESS_WIDTH-1:0] p2_health100_colorAddr; 	 // Color address for the color palette
	assign p2_health_imgAddress = p2_health1_x + HEALTH_WIDTH*p2_health1_y;				 // Address calculated coordinate
	
	VRAM #(		
		.DEPTH(HEALTH_PIXEL_COUNT), 		            // Set RAM depth to contain every pixel
		.DATA_WIDTH(PALETTE_ADDRESS_WIDTH),             // Set data width according to the color palette
		.ADDRESS_WIDTH(HEALTH_PIXEL_ADDRESS_WIDTH),     // Set address with according to the pixel count
		.MEMFILE({MEM_FILES_PATH, "health/health_mem/health_100image.mem"}))            // Memory initialization
	ImageData31(
		.clk(clk), 						         // Falling edge of the 100 MHz clk
		.addr(p2_health_imgAddress),					 // Image data address
		.dataOut(p2_health100_colorAddr),
		.wEn(1'b0)); 						  
	
	// Color Palette to Map Color Address to 12-Bit Color
	wire[BITS_PER_COLOR-1:0] p2_health100_ColorData; // 12-bit color data at current pixel
	
	VRAM #(
		.DEPTH(PALETTE_COLOR_COUNT), 		       // Set depth to contain every color		
		.DATA_WIDTH(BITS_PER_COLOR), 		       // Set data width according to the bits per color
		.ADDRESS_WIDTH(PALETTE_ADDRESS_WIDTH),     // Set address width according to the color count
		.MEMFILE({MEM_FILES_PATH, "health/health_mem/health_100colors.mem"}))  // Memory initialization
	ColorPalette31(
		.clk(clk), 							   	   // Rising edge of the 100 MHz clk
		.addr(p2_health100_colorAddr),					   // Address from the ImageData RAM
		.dataOut(p2_health100_ColorData),
		.wEn(1'b0)); 						     


	wire[PALETTE_ADDRESS_WIDTH-1:0] p2_health95_colorAddr; 	 // Color address for the color palette
	VRAM #(		
		.DEPTH(HEALTH_PIXEL_COUNT), 		            // Set RAM depth to contain every pixel
		.DATA_WIDTH(PALETTE_ADDRESS_WIDTH),             // Set data width according to the color palette
		.ADDRESS_WIDTH(HEALTH_PIXEL_ADDRESS_WIDTH),     // Set address with according to the pixel count
		.MEMFILE({MEM_FILES_PATH, "health/health_mem/health_95image.mem"}))            // Memory initialization
	ImageData32(
		.clk(clk), 						         // Falling edge of the 100 MHz clk
		.addr(p2_health_imgAddress),					 // Image data address
		.dataOut(p2_health95_colorAddr),
		.wEn(1'b0)); 						  
	
	// Color Palette to Map Color Address to 12-Bit Color
	wire[BITS_PER_COLOR-1:0] p2_health95_ColorData; // 12-bit color data at current pixel
	
	VRAM #(
		.DEPTH(PALETTE_COLOR_COUNT), 		       // Set depth to contain every color		
		.DATA_WIDTH(BITS_PER_COLOR), 		       // Set data width according to the bits per color
		.ADDRESS_WIDTH(PALETTE_ADDRESS_WIDTH),     // Set address width according to the color count
		.MEMFILE({MEM_FILES_PATH, "health/health_mem/health_95colors.mem"}))  // Memory initialization
	ColorPalette32(
		.clk(clk), 							   	   // Rising edge of the 100 MHz clk
		.addr(p2_health95_colorAddr),					   // Address from the ImageData RAM
		.dataOut(p2_health95_ColorData),
		.wEn(1'b0)); 				





	wire[PALETTE_ADDRESS_WIDTH-1:0] p2_health90_colorAddr; 	 // Color address for the color palette
	VRAM #(		
		.DEPTH(HEALTH_PIXEL_COUNT), 		            // Set RAM depth to contain every pixel
		.DATA_WIDTH(PALETTE_ADDRESS_WIDTH),             // Set data width according to the color palette
		.ADDRESS_WIDTH(HEALTH_PIXEL_ADDRESS_WIDTH),     // Set address with according to the pixel count
		.MEMFILE({MEM_FILES_PATH, "health/health_mem/health_90image.mem"}))            // Memory initialization
	ImageData33(
		.clk(clk), 						         // Falling edge of the 100 MHz clk
		.addr(p2_health_imgAddress),					 // Image data address
		.dataOut(p2_health90_colorAddr),
		.wEn(1'b0)); 						  
	
	// Color Palette to Map Color Address to 12-Bit Color
	wire[BITS_PER_COLOR-1:0] p2_health90_ColorData; // 12-bit color data at current pixel
	
	VRAM #(
		.DEPTH(PALETTE_COLOR_COUNT), 		       // Set depth to contain every color		
		.DATA_WIDTH(BITS_PER_COLOR), 		       // Set data width according to the bits per color
		.ADDRESS_WIDTH(PALETTE_ADDRESS_WIDTH),     // Set address width according to the color count
		.MEMFILE({MEM_FILES_PATH, "health/health_mem/health_90colors.mem"}))  // Memory initialization
	ColorPalette33(
		.clk(clk), 							   	   // Rising edge of the 100 MHz clk
		.addr(p2_health90_colorAddr),					   // Address from the ImageData RAM
		.dataOut(p2_health90_ColorData),
		.wEn(1'b0));		     

	
	wire[PALETTE_ADDRESS_WIDTH-1:0] p2_health85_colorAddr; 	 // Color address for the color palette
	VRAM #(		
		.DEPTH(HEALTH_PIXEL_COUNT), 		            // Set RAM depth to contain every pixel
		.DATA_WIDTH(PALETTE_ADDRESS_WIDTH),             // Set data width according to the color palette
		.ADDRESS_WIDTH(HEALTH_PIXEL_ADDRESS_WIDTH),     // Set address with according to the pixel count
		.MEMFILE({MEM_FILES_PATH, "health/health_mem/health_85image.mem"}))            // Memory initialization
	ImageData34(
		.clk(clk), 						         // Falling edge of the 100 MHz clk
		.addr(p2_health_imgAddress),					 // Image data address
		.dataOut(p2_health85_colorAddr),
		.wEn(1'b0)); 						  
	
	// Color Palette to Map Color Address to 12-Bit Color
	wire[BITS_PER_COLOR-1:0] p2_health85_ColorData; // 12-bit color data at current pixel
	
	VRAM #(
		.DEPTH(PALETTE_COLOR_COUNT), 		       // Set depth to contain every color		
		.DATA_WIDTH(BITS_PER_COLOR), 		       // Set data width according to the bits per color
		.ADDRESS_WIDTH(PALETTE_ADDRESS_WIDTH),     // Set address width according to the color count
		.MEMFILE({MEM_FILES_PATH, "health/health_mem/health_85colors.mem"}))  // Memory initialization
	ColorPalette34(
		.clk(clk), 							   	   // Rising edge of the 100 MHz clk
		.addr(p2_health85_colorAddr),					   // Address from the ImageData RAM
		.dataOut(p2_health85_ColorData),
		.wEn(1'b0));

	
	wire[PALETTE_ADDRESS_WIDTH-1:0] p2_health80_colorAddr; 	 // Color address for the color palette
	VRAM #(		
		.DEPTH(HEALTH_PIXEL_COUNT), 		            // Set RAM depth to contain every pixel
		.DATA_WIDTH(PALETTE_ADDRESS_WIDTH),             // Set data width according to the color palette
		.ADDRESS_WIDTH(HEALTH_PIXEL_ADDRESS_WIDTH),     // Set address with according to the pixel count
		.MEMFILE({MEM_FILES_PATH, "health/health_mem/health_80image.mem"}))            // Memory initialization
	ImageData35(
		.clk(clk), 						         // Falling edge of the 100 MHz clk
		.addr(p2_health_imgAddress),					 // Image data address
		.dataOut(p2_health80_colorAddr),
		.wEn(1'b0)); 						  
	
	// Color Palette to Map Color Address to 12-Bit Color
	wire[BITS_PER_COLOR-1:0] p2_health80_ColorData; // 12-bit color data at current pixel
	
	VRAM #(
		.DEPTH(PALETTE_COLOR_COUNT), 		       // Set depth to contain every color		
		.DATA_WIDTH(BITS_PER_COLOR), 		       // Set data width according to the bits per color
		.ADDRESS_WIDTH(PALETTE_ADDRESS_WIDTH),     // Set address width according to the color count
		.MEMFILE({MEM_FILES_PATH, "health/health_mem/health_80colors.mem"}))  // Memory initialization
	ColorPalette35(
		.clk(clk), 							   	   // Rising edge of the 100 MHz clk
		.addr(p2_health80_colorAddr),					   // Address from the ImageData RAM
		.dataOut(p2_health80_ColorData),
		.wEn(1'b0));


	wire[PALETTE_ADDRESS_WIDTH-1:0] p2_health75_colorAddr; 	 // Color address for the color palette
	VRAM #(		
		.DEPTH(HEALTH_PIXEL_COUNT), 		            // Set RAM depth to contain every pixel
		.DATA_WIDTH(PALETTE_ADDRESS_WIDTH),             // Set data width according to the color palette
		.ADDRESS_WIDTH(HEALTH_PIXEL_ADDRESS_WIDTH),     // Set address with according to the pixel count
		.MEMFILE({MEM_FILES_PATH, "health/health_mem/health_75image.mem"}))            // Memory initialization
	ImageData36(
		.clk(clk), 						         // Falling edge of the 100 MHz clk
		.addr(p2_health_imgAddress),					 // Image data address
		.dataOut(p2_health75_colorAddr),
		.wEn(1'b0)); 						  
	
	// Color Palette to Map Color Address to 12-Bit Color
	wire[BITS_PER_COLOR-1:0] p2_health75_ColorData; // 12-bit color data at current pixel
	
	VRAM #(
		.DEPTH(PALETTE_COLOR_COUNT), 		       // Set depth to contain every color		
		.DATA_WIDTH(BITS_PER_COLOR), 		       // Set data width according to the bits per color
		.ADDRESS_WIDTH(PALETTE_ADDRESS_WIDTH),     // Set address width according to the color count
		.MEMFILE({MEM_FILES_PATH, "health/health_mem/health_75colors.mem"}))  // Memory initialization
	ColorPalette36(
		.clk(clk), 							   	   // Rising edge of the 100 MHz clk
		.addr(p2_health75_colorAddr),					   // Address from the ImageData RAM
		.dataOut(p2_health75_ColorData),
		.wEn(1'b0));

	
	wire[PALETTE_ADDRESS_WIDTH-1:0] p2_health70_colorAddr; 	 // Color address for the color palette
	VRAM #(		
		.DEPTH(HEALTH_PIXEL_COUNT), 		            // Set RAM depth to contain every pixel
		.DATA_WIDTH(PALETTE_ADDRESS_WIDTH),             // Set data width according to the color palette
		.ADDRESS_WIDTH(HEALTH_PIXEL_ADDRESS_WIDTH),     // Set address with according to the pixel count
		.MEMFILE({MEM_FILES_PATH, "health/health_mem/health_70image.mem"}))            // Memory initialization
	ImageData37(
		.clk(clk), 						         // Falling edge of the 100 MHz clk
		.addr(p2_health_imgAddress),					 // Image data address
		.dataOut(p2_health70_colorAddr),
		.wEn(1'b0)); 						  
	
	// Color Palette to Map Color Address to 12-Bit Color
	wire[BITS_PER_COLOR-1:0] p2_health70_ColorData; // 12-bit color data at current pixel
	
	VRAM #(
		.DEPTH(PALETTE_COLOR_COUNT), 		       // Set depth to contain every color		
		.DATA_WIDTH(BITS_PER_COLOR), 		       // Set data width according to the bits per color
		.ADDRESS_WIDTH(PALETTE_ADDRESS_WIDTH),     // Set address width according to the color count
		.MEMFILE({MEM_FILES_PATH, "health/health_mem/health_70colors.mem"}))  // Memory initialization
	ColorPalette37(
		.clk(clk), 							   	   // Rising edge of the 100 MHz clk
		.addr(p2_health70_colorAddr),					   // Address from the ImageData RAM
		.dataOut(p2_health70_ColorData),
		.wEn(1'b0));

	
	wire[PALETTE_ADDRESS_WIDTH-1:0] p2_health65_colorAddr; 	 // Color address for the color palette
	VRAM #(		
		.DEPTH(HEALTH_PIXEL_COUNT), 		            // Set RAM depth to contain every pixel
		.DATA_WIDTH(PALETTE_ADDRESS_WIDTH),             // Set data width according to the color palette
		.ADDRESS_WIDTH(HEALTH_PIXEL_ADDRESS_WIDTH),     // Set address with according to the pixel count
		.MEMFILE({MEM_FILES_PATH, "health/health_mem/health_65image.mem"}))            // Memory initialization
	ImageData38(
		.clk(clk), 						         // Falling edge of the 100 MHz clk
		.addr(p2_health_imgAddress),					 // Image data address
		.dataOut(p2_health65_colorAddr),
		.wEn(1'b0)); 						  
	
	// Color Palette to Map Color Address to 12-Bit Color
	wire[BITS_PER_COLOR-1:0] p2_health65_ColorData; // 12-bit color data at current pixel
	
	VRAM #(
		.DEPTH(PALETTE_COLOR_COUNT), 		       // Set depth to contain every color		
		.DATA_WIDTH(BITS_PER_COLOR), 		       // Set data width according to the bits per color
		.ADDRESS_WIDTH(PALETTE_ADDRESS_WIDTH),     // Set address width according to the color count
		.MEMFILE({MEM_FILES_PATH, "health/health_mem/health_65colors.mem"}))  // Memory initialization
	ColorPalette38(
		.clk(clk), 							   	   // Rising edge of the 100 MHz clk
		.addr(p2_health65_colorAddr),					   // Address from the ImageData RAM
		.dataOut(p2_health65_ColorData),
		.wEn(1'b0));


	wire[PALETTE_ADDRESS_WIDTH-1:0] p2_health60_colorAddr; 	 // Color address for the color palette
	VRAM #(		
		.DEPTH(HEALTH_PIXEL_COUNT), 		            // Set RAM depth to contain every pixel
		.DATA_WIDTH(PALETTE_ADDRESS_WIDTH),             // Set data width according to the color palette
		.ADDRESS_WIDTH(HEALTH_PIXEL_ADDRESS_WIDTH),     // Set address with according to the pixel count
		.MEMFILE({MEM_FILES_PATH, "health/health_mem/health_60image.mem"}))            // Memory initialization
	ImageData39(
		.clk(clk), 						         // Falling edge of the 100 MHz clk
		.addr(p2_health_imgAddress),					 // Image data address
		.dataOut(p2_health60_colorAddr),
		.wEn(1'b0)); 						  
	
	// Color Palette to Map Color Address to 12-Bit Color
	wire[BITS_PER_COLOR-1:0] p2_health60_ColorData; // 12-bit color data at current pixel
	
	VRAM #(
		.DEPTH(PALETTE_COLOR_COUNT), 		       // Set depth to contain every color		
		.DATA_WIDTH(BITS_PER_COLOR), 		       // Set data width according to the bits per color
		.ADDRESS_WIDTH(PALETTE_ADDRESS_WIDTH),     // Set address width according to the color count
		.MEMFILE({MEM_FILES_PATH, "health/health_mem/health_60colors.mem"}))  // Memory initialization
	ColorPalette39(
		.clk(clk), 							   	   // Rising edge of the 100 MHz clk
		.addr(p2_health60_colorAddr),					   // Address from the ImageData RAM
		.dataOut(p2_health60_ColorData),
		.wEn(1'b0));

	wire[PALETTE_ADDRESS_WIDTH-1:0] p2_health55_colorAddr; 	 // Color address for the color palette
	VRAM #(		
		.DEPTH(HEALTH_PIXEL_COUNT), 		            // Set RAM depth to contain every pixel
		.DATA_WIDTH(PALETTE_ADDRESS_WIDTH),             // Set data width according to the color palette
		.ADDRESS_WIDTH(HEALTH_PIXEL_ADDRESS_WIDTH),     // Set address with according to the pixel count
		.MEMFILE({MEM_FILES_PATH, "health/health_mem/health_55image.mem"}))            // Memory initialization
	ImageData40(
		.clk(clk), 						         // Falling edge of the 100 MHz clk
		.addr(p2_health_imgAddress),					 // Image data address
		.dataOut(p2_health55_colorAddr),
		.wEn(1'b0)); 						  
	
	// Color Palette to Map Color Address to 12-Bit Color
	wire[BITS_PER_COLOR-1:0] p2_health55_ColorData; // 12-bit color data at current pixel
	
	VRAM #(
		.DEPTH(PALETTE_COLOR_COUNT), 		       // Set depth to contain every color		
		.DATA_WIDTH(BITS_PER_COLOR), 		       // Set data width according to the bits per color
		.ADDRESS_WIDTH(PALETTE_ADDRESS_WIDTH),     // Set address width according to the color count
		.MEMFILE({MEM_FILES_PATH, "health/health_mem/health_55colors.mem"}))  // Memory initialization
	ColorPalette40(
		.clk(clk), 							   	   // Rising edge of the 100 MHz clk
		.addr(p2_health55_colorAddr),					   // Address from the ImageData RAM
		.dataOut(p2_health55_ColorData),
		.wEn(1'b0));

	
	wire[PALETTE_ADDRESS_WIDTH-1:0] p2_health50_colorAddr; 	 // Color address for the color palette
	VRAM #(		
		.DEPTH(HEALTH_PIXEL_COUNT), 		            // Set RAM depth to contain every pixel
		.DATA_WIDTH(PALETTE_ADDRESS_WIDTH),             // Set data width according to the color palette
		.ADDRESS_WIDTH(HEALTH_PIXEL_ADDRESS_WIDTH),     // Set address with according to the pixel count
		.MEMFILE({MEM_FILES_PATH, "health/health_mem/health_50image.mem"}))            // Memory initialization
	ImageData41(
		.clk(clk), 						         // Falling edge of the 100 MHz clk
		.addr(p2_health_imgAddress),					 // Image data address
		.dataOut(p2_health50_colorAddr),
		.wEn(1'b0)); 						  
	
	// Color Palette to Map Color Address to 12-Bit Color
	wire[BITS_PER_COLOR-1:0] p2_health50_ColorData; // 12-bit color data at current pixel
	
	VRAM #(
		.DEPTH(PALETTE_COLOR_COUNT), 		       // Set depth to contain every color		
		.DATA_WIDTH(BITS_PER_COLOR), 		       // Set data width according to the bits per color
		.ADDRESS_WIDTH(PALETTE_ADDRESS_WIDTH),     // Set address width according to the color count
		.MEMFILE({MEM_FILES_PATH, "health/health_mem/health_50colors.mem"}))  // Memory initialization
	ColorPalette41(
		.clk(clk), 							   	   // Rising edge of the 100 MHz clk
		.addr(p2_health50_colorAddr),					   // Address from the ImageData RAM
		.dataOut(p2_health50_ColorData),
		.wEn(1'b0));


	wire[PALETTE_ADDRESS_WIDTH-1:0] p2_health45_colorAddr; 	 // Color address for the color palette
	VRAM #(		
		.DEPTH(HEALTH_PIXEL_COUNT), 		            // Set RAM depth to contain every pixel
		.DATA_WIDTH(PALETTE_ADDRESS_WIDTH),             // Set data width according to the color palette
		.ADDRESS_WIDTH(HEALTH_PIXEL_ADDRESS_WIDTH),     // Set address with according to the pixel count
		.MEMFILE({MEM_FILES_PATH, "health/health_mem/health_45image.mem"}))            // Memory initialization
	ImageData42(
		.clk(clk), 						         // Falling edge of the 100 MHz clk
		.addr(p2_health_imgAddress),					 // Image data address
		.dataOut(p2_health45_colorAddr),
		.wEn(1'b0)); 						  
	
	// Color Palette to Map Color Address to 12-Bit Color
	wire[BITS_PER_COLOR-1:0] p2_health45_ColorData; // 12-bit color data at current pixel
	
	VRAM #(
		.DEPTH(PALETTE_COLOR_COUNT), 		       // Set depth to contain every color		
		.DATA_WIDTH(BITS_PER_COLOR), 		       // Set data width according to the bits per color
		.ADDRESS_WIDTH(PALETTE_ADDRESS_WIDTH),     // Set address width according to the color count
		.MEMFILE({MEM_FILES_PATH, "health/health_mem/health_45colors.mem"}))  // Memory initialization
	ColorPalette42(
		.clk(clk), 							   	   // Rising edge of the 100 MHz clk
		.addr(p2_health45_colorAddr),					   // Address from the ImageData RAM
		.dataOut(p2_health45_ColorData),
		.wEn(1'b0));


	wire[PALETTE_ADDRESS_WIDTH-1:0] p2_health40_colorAddr; 	 // Color address for the color palette
	VRAM #(		
		.DEPTH(HEALTH_PIXEL_COUNT), 		            // Set RAM depth to contain every pixel
		.DATA_WIDTH(PALETTE_ADDRESS_WIDTH),             // Set data width according to the color palette
		.ADDRESS_WIDTH(HEALTH_PIXEL_ADDRESS_WIDTH),     // Set address with according to the pixel count
		.MEMFILE({MEM_FILES_PATH, "health/health_mem/health_40image.mem"}))            // Memory initialization
	ImageData43(
		.clk(clk), 						         // Falling edge of the 100 MHz clk
		.addr(p2_health_imgAddress),					 // Image data address
		.dataOut(p2_health40_colorAddr),
		.wEn(1'b0)); 						  
	
	// Color Palette to Map Color Address to 12-Bit Color
	wire[BITS_PER_COLOR-1:0] p2_health40_ColorData; // 12-bit color data at current pixel
	
	VRAM #(
		.DEPTH(PALETTE_COLOR_COUNT), 		       // Set depth to contain every color		
		.DATA_WIDTH(BITS_PER_COLOR), 		       // Set data width according to the bits per color
		.ADDRESS_WIDTH(PALETTE_ADDRESS_WIDTH),     // Set address width according to the color count
		.MEMFILE({MEM_FILES_PATH, "health/health_mem/health_40colors.mem"}))  // Memory initialization
	ColorPalette43(
		.clk(clk), 							   	   // Rising edge of the 100 MHz clk
		.addr(p2_health40_colorAddr),					   // Address from the ImageData RAM
		.dataOut(p2_health40_ColorData),
		.wEn(1'b0));


	wire[PALETTE_ADDRESS_WIDTH-1:0] p2_health35_colorAddr; 	 // Color address for the color palette
	VRAM #(		
		.DEPTH(HEALTH_PIXEL_COUNT), 		            // Set RAM depth to contain every pixel
		.DATA_WIDTH(PALETTE_ADDRESS_WIDTH),             // Set data width according to the color palette
		.ADDRESS_WIDTH(HEALTH_PIXEL_ADDRESS_WIDTH),     // Set address with according to the pixel count
		.MEMFILE({MEM_FILES_PATH, "health/health_mem/health_35image.mem"}))            // Memory initialization
	ImageData44(
		.clk(clk), 						         // Falling edge of the 100 MHz clk
		.addr(p2_health_imgAddress),					 // Image data address
		.dataOut(p2_health35_colorAddr),
		.wEn(1'b0)); 						  
	
	// Color Palette to Map Color Address to 12-Bit Color
	wire[BITS_PER_COLOR-1:0] p2_health35_ColorData; // 12-bit color data at current pixel
	
	VRAM #(
		.DEPTH(PALETTE_COLOR_COUNT), 		       // Set depth to contain every color		
		.DATA_WIDTH(BITS_PER_COLOR), 		       // Set data width according to the bits per color
		.ADDRESS_WIDTH(PALETTE_ADDRESS_WIDTH),     // Set address width according to the color count
		.MEMFILE({MEM_FILES_PATH, "health/health_mem/health_35colors.mem"}))  // Memory initialization
	ColorPalette44(
		.clk(clk), 							   	   // Rising edge of the 100 MHz clk
		.addr(p2_health35_colorAddr),					   // Address from the ImageData RAM
		.dataOut(p2_health35_ColorData),
		.wEn(1'b0));


	wire[PALETTE_ADDRESS_WIDTH-1:0] p2_health30_colorAddr; 	 // Color address for the color palette
	VRAM #(		
		.DEPTH(HEALTH_PIXEL_COUNT), 		            // Set RAM depth to contain every pixel
		.DATA_WIDTH(PALETTE_ADDRESS_WIDTH),             // Set data width according to the color palette
		.ADDRESS_WIDTH(HEALTH_PIXEL_ADDRESS_WIDTH),     // Set address with according to the pixel count
		.MEMFILE({MEM_FILES_PATH, "health/health_mem/health_30image.mem"}))            // Memory initialization
	ImageData45(
		.clk(clk), 						         // Falling edge of the 100 MHz clk
		.addr(p2_health_imgAddress),					 // Image data address
		.dataOut(p2_health30_colorAddr),
		.wEn(1'b0)); 						  
	
	// Color Palette to Map Color Address to 12-Bit Color
	wire[BITS_PER_COLOR-1:0] p2_health30_ColorData; // 12-bit color data at current pixel
	
	VRAM #(
		.DEPTH(PALETTE_COLOR_COUNT), 		       // Set depth to contain every color		
		.DATA_WIDTH(BITS_PER_COLOR), 		       // Set data width according to the bits per color
		.ADDRESS_WIDTH(PALETTE_ADDRESS_WIDTH),     // Set address width according to the color count
		.MEMFILE({MEM_FILES_PATH, "health/health_mem/health_30colors.mem"}))  // Memory initialization
	ColorPalette45(
		.clk(clk), 							   	   // Rising edge of the 100 MHz clk
		.addr(p2_health30_colorAddr),					   // Address from the ImageData RAM
		.dataOut(p2_health30_ColorData),
		.wEn(1'b0));


	wire[PALETTE_ADDRESS_WIDTH-1:0] p2_health25_colorAddr; 	 // Color address for the color palette
	VRAM #(		
		.DEPTH(HEALTH_PIXEL_COUNT), 		            // Set RAM depth to contain every pixel
		.DATA_WIDTH(PALETTE_ADDRESS_WIDTH),             // Set data width according to the color palette
		.ADDRESS_WIDTH(HEALTH_PIXEL_ADDRESS_WIDTH),     // Set address with according to the pixel count
		.MEMFILE({MEM_FILES_PATH, "health/health_mem/health_25image.mem"}))            // Memory initialization
	ImageData46(
		.clk(clk), 						         // Falling edge of the 100 MHz clk
		.addr(p2_health_imgAddress),					 // Image data address
		.dataOut(p2_health25_colorAddr),
		.wEn(1'b0)); 						  
	
	// Color Palette to Map Color Address to 12-Bit Color
	wire[BITS_PER_COLOR-1:0] p2_health25_ColorData; // 12-bit color data at current pixel
	
	VRAM #(
		.DEPTH(PALETTE_COLOR_COUNT), 		       // Set depth to contain every color		
		.DATA_WIDTH(BITS_PER_COLOR), 		       // Set data width according to the bits per color
		.ADDRESS_WIDTH(PALETTE_ADDRESS_WIDTH),     // Set address width according to the color count
		.MEMFILE({MEM_FILES_PATH, "health/health_mem/health_25colors.mem"}))  // Memory initialization
	ColorPalette46(
		.clk(clk), 							   	   // Rising edge of the 100 MHz clk
		.addr(p2_health25_colorAddr),					   // Address from the ImageData RAM
		.dataOut(p2_health25_ColorData),
		.wEn(1'b0));

	
	wire[PALETTE_ADDRESS_WIDTH-1:0] p2_health20_colorAddr; 	 // Color address for the color palette
	VRAM #(		
		.DEPTH(HEALTH_PIXEL_COUNT), 		            // Set RAM depth to contain every pixel
		.DATA_WIDTH(PALETTE_ADDRESS_WIDTH),             // Set data width according to the color palette
		.ADDRESS_WIDTH(HEALTH_PIXEL_ADDRESS_WIDTH),     // Set address with according to the pixel count
		.MEMFILE({MEM_FILES_PATH, "health/health_mem/health_20image.mem"}))            // Memory initialization
	ImageData47(
		.clk(clk), 						         // Falling edge of the 100 MHz clk
		.addr(p2_health_imgAddress),					 // Image data address
		.dataOut(p2_health20_colorAddr),
		.wEn(1'b0)); 						  
	
	// Color Palette to Map Color Address to 12-Bit Color
	wire[BITS_PER_COLOR-1:0] p2_health20_ColorData; // 12-bit color data at current pixel
	
	VRAM #(
		.DEPTH(PALETTE_COLOR_COUNT), 		       // Set depth to contain every color		
		.DATA_WIDTH(BITS_PER_COLOR), 		       // Set data width according to the bits per color
		.ADDRESS_WIDTH(PALETTE_ADDRESS_WIDTH),     // Set address width according to the color count
		.MEMFILE({MEM_FILES_PATH, "health/health_mem/health_20colors.mem"}))  // Memory initialization
	ColorPalette47(
		.clk(clk), 							   	   // Rising edge of the 100 MHz clk
		.addr(p2_health20_colorAddr),					   // Address from the ImageData RAM
		.dataOut(p2_health20_ColorData),
		.wEn(1'b0));


	wire[PALETTE_ADDRESS_WIDTH-1:0] p2_health15_colorAddr; 	 // Color address for the color palette
	VRAM #(		
		.DEPTH(HEALTH_PIXEL_COUNT), 		            // Set RAM depth to contain every pixel
		.DATA_WIDTH(PALETTE_ADDRESS_WIDTH),             // Set data width according to the color palette
		.ADDRESS_WIDTH(HEALTH_PIXEL_ADDRESS_WIDTH),     // Set address with according to the pixel count
		.MEMFILE({MEM_FILES_PATH, "health/health_mem/health_15image.mem"}))            // Memory initialization
	ImageData48(
		.clk(clk), 						         // Falling edge of the 100 MHz clk
		.addr(p2_health_imgAddress),					 // Image data address
		.dataOut(p2_health15_colorAddr),
		.wEn(1'b0)); 						  
	
	// Color Palette to Map Color Address to 12-Bit Color
	wire[BITS_PER_COLOR-1:0] p2_health15_ColorData; // 12-bit color data at current pixel
	
	VRAM #(
		.DEPTH(PALETTE_COLOR_COUNT), 		       // Set depth to contain every color		
		.DATA_WIDTH(BITS_PER_COLOR), 		       // Set data width according to the bits per color
		.ADDRESS_WIDTH(PALETTE_ADDRESS_WIDTH),     // Set address width according to the color count
		.MEMFILE({MEM_FILES_PATH, "health/health_mem/health_15colors.mem"}))  // Memory initialization
	ColorPalette48(
		.clk(clk), 							   	   // Rising edge of the 100 MHz clk
		.addr(p2_health15_colorAddr),					   // Address from the ImageData RAM
		.dataOut(p2_health15_ColorData),
		.wEn(1'b0));

	
	wire[PALETTE_ADDRESS_WIDTH-1:0] p2_health10_colorAddr; 	 // Color address for the color palette
	VRAM #(		
		.DEPTH(HEALTH_PIXEL_COUNT), 		            // Set RAM depth to contain every pixel
		.DATA_WIDTH(PALETTE_ADDRESS_WIDTH),             // Set data width according to the color palette
		.ADDRESS_WIDTH(HEALTH_PIXEL_ADDRESS_WIDTH),     // Set address with according to the pixel count
		.MEMFILE({MEM_FILES_PATH, "health/health_mem/health_10image.mem"}))            // Memory initialization
	ImageData49(
		.clk(clk), 						         // Falling edge of the 100 MHz clk
		.addr(p2_health_imgAddress),					 // Image data address
		.dataOut(p2_health10_colorAddr),
		.wEn(1'b0)); 						  
	
	// Color Palette to Map Color Address to 12-Bit Color
	wire[BITS_PER_COLOR-1:0] p2_health10_ColorData; // 12-bit color data at current pixel
	
	VRAM #(
		.DEPTH(PALETTE_COLOR_COUNT), 		       // Set depth to contain every color		
		.DATA_WIDTH(BITS_PER_COLOR), 		       // Set data width according to the bits per color
		.ADDRESS_WIDTH(PALETTE_ADDRESS_WIDTH),     // Set address width according to the color count
		.MEMFILE({MEM_FILES_PATH, "health/health_mem/health_10colors.mem"}))  // Memory initialization
	ColorPalette49(
		.clk(clk), 							   	   // Rising edge of the 100 MHz clk
		.addr(p2_health10_colorAddr),					   // Address from the ImageData RAM
		.dataOut(p2_health10_ColorData),
		.wEn(1'b0));


	wire[PALETTE_ADDRESS_WIDTH-1:0] p2_health5_colorAddr; 	 // Color address for the color palette
	VRAM #(		
		.DEPTH(HEALTH_PIXEL_COUNT), 		            // Set RAM depth to contain every pixel
		.DATA_WIDTH(PALETTE_ADDRESS_WIDTH),             // Set data width according to the color palette
		.ADDRESS_WIDTH(HEALTH_PIXEL_ADDRESS_WIDTH),     // Set address with according to the pixel count
		.MEMFILE({MEM_FILES_PATH, "health/health_mem/health_5image.mem"}))            // Memory initialization
	ImageData50(
		.clk(clk), 						         // Falling edge of the 100 MHz clk
		.addr(p2_health_imgAddress),					 // Image data address
		.dataOut(p2_health5_colorAddr),
		.wEn(1'b0)); 						  
	
	// Color Palette to Map Color Address to 12-Bit Color
	wire[BITS_PER_COLOR-1:0] p2_health5_ColorData; // 12-bit color data at current pixel
	
	VRAM #(
		.DEPTH(PALETTE_COLOR_COUNT), 		       // Set depth to contain every color		
		.DATA_WIDTH(BITS_PER_COLOR), 		       // Set data width according to the bits per color
		.ADDRESS_WIDTH(PALETTE_ADDRESS_WIDTH),     // Set address width according to the color count
		.MEMFILE({MEM_FILES_PATH, "health/health_mem/health_5colors.mem"}))  // Memory initialization
	ColorPalette50(
		.clk(clk), 							   	   // Rising edge of the 100 MHz clk
		.addr(p2_health5_colorAddr),					   // Address from the ImageData RAM
		.dataOut(p2_health5_ColorData),
		.wEn(1'b0));


	wire[PALETTE_ADDRESS_WIDTH-1:0] p2_health0_colorAddr; 	 // Color address for the color palette
	VRAM #(		
		.DEPTH(HEALTH_PIXEL_COUNT), 		            // Set RAM depth to contain every pixel
		.DATA_WIDTH(PALETTE_ADDRESS_WIDTH),             // Set data width according to the color palette
		.ADDRESS_WIDTH(HEALTH_PIXEL_ADDRESS_WIDTH),     // Set address with according to the pixel count
		.MEMFILE({MEM_FILES_PATH, "health/health_mem/health_0image.mem"}))            // Memory initialization
	ImageData51(
		.clk(clk), 						         // Falling edge of the 100 MHz clk
		.addr(p2_health_imgAddress),					 // Image data address
		.dataOut(p2_health0_colorAddr),
		.wEn(1'b0)); 						  
	
	// Color Palette to Map Color Address to 12-Bit Color
	wire[BITS_PER_COLOR-1:0] p2_health0_ColorData; // 12-bit color data at current pixel
	
	VRAM #(
		.DEPTH(PALETTE_COLOR_COUNT), 		       // Set depth to contain every color		
		.DATA_WIDTH(BITS_PER_COLOR), 		       // Set data width according to the bits per color
		.ADDRESS_WIDTH(PALETTE_ADDRESS_WIDTH),     // Set address width according to the color count
		.MEMFILE({MEM_FILES_PATH, "health/health_mem/health_0colors.mem"}))  // Memory initialization
	ColorPalette51(
		.clk(clk), 							   	   // Rising edge of the 100 MHz clk
		.addr(p2_health0_colorAddr),					   // Address from the ImageData RAM
		.dataOut(p2_health0_ColorData),
		.wEn(1'b0));







	// Assign to output color from register if active
	wire[BITS_PER_COLOR-1:0] colorOut; 			  // Output color 
	wire [11:0] bulletColorData = 12'hF00; // Red color for bullets

	assign colorOut = active ? 
    	(p1isInSquare ? sprite1ColorData : 
    	p2isInSquare ? sprite2ColorData :
     	isBulletActive ? bulletColorData :
		(isInP1Health && p1Health == 100) ? p1_health100_ColorData :
		(isInP1Health && p1Health == 95) ? p1_health95_ColorData :
		(isInP1Health && p1Health == 90) ? p1_health90_ColorData :
		(isInP1Health && p1Health == 85) ? p1_health85_ColorData :
		(isInP1Health && p1Health == 80) ? p1_health80_ColorData :
		(isInP1Health && p1Health == 75) ? p1_health75_ColorData :
		(isInP1Health && p1Health == 70) ? p1_health70_ColorData :
		(isInP1Health && p1Health == 65) ? p1_health65_ColorData :
		(isInP1Health && p1Health == 60) ? p1_health60_ColorData :
		(isInP1Health && p1Health == 55) ? p1_health55_ColorData :
		(isInP1Health && p1Health == 50) ? p1_health50_ColorData :
		(isInP1Health && p1Health == 45) ? p1_health45_ColorData :
		(isInP1Health && p1Health == 40) ? p1_health40_ColorData :
		(isInP1Health && p1Health == 35) ? p1_health35_ColorData :
		(isInP1Health && p1Health == 30) ? p1_health30_ColorData :
		(isInP1Health && p1Health == 25) ? p1_health25_ColorData :
		(isInP1Health && p1Health == 20) ? p1_health20_ColorData :
		(isInP1Health && p1Health == 15) ? p1_health15_ColorData :
		(isInP1Health && p1Health == 10) ? p1_health10_ColorData :
		(isInP1Health && p1Health == 5) ? p1_health5_ColorData :
		(isInP1Health && p1Health == 0) ? p1_health0_ColorData :
		(isInP2Health && p2Health == 100) ? p2_health100_ColorData :
		(isInP2Health && p2Health == 95) ? p2_health95_ColorData :
		(isInP2Health && p2Health == 90) ? p2_health90_ColorData :
		(isInP2Health && p2Health == 85) ? p2_health85_ColorData :
		(isInP2Health && p2Health == 80) ? p2_health80_ColorData :
		(isInP2Health && p2Health == 75) ? p2_health75_ColorData :
		(isInP2Health && p2Health == 70) ? p2_health70_ColorData :
		(isInP2Health && p2Health == 65) ? p2_health65_ColorData :
		(isInP2Health && p2Health == 60) ? p2_health60_ColorData :
		(isInP2Health && p2Health == 55) ? p2_health55_ColorData :
		(isInP2Health && p2Health == 50) ? p2_health50_ColorData :
		(isInP2Health && p2Health == 45) ? p2_health45_ColorData :
		(isInP2Health && p2Health == 40) ? p2_health40_ColorData :
		(isInP2Health && p2Health == 35) ? p2_health35_ColorData :
		(isInP2Health && p2Health == 30) ? p2_health30_ColorData :
		(isInP2Health && p2Health == 25) ? p2_health25_ColorData :
		(isInP2Health && p2Health == 20) ? p2_health20_ColorData :
		(isInP2Health && p2Health == 15) ? p2_health15_ColorData :
		(isInP2Health && p2Health == 10) ? p2_health10_ColorData :
		(isInP2Health && p2Health == 5) ? p2_health5_ColorData :
		(isInP2Health && p2Health == 0) ? p2_health0_ColorData :
		// (p1Health == 0) ? startScreen1colorData : 
		colorData) : 
    	12'd0; // Black when not active

	// Quickly assign the output colors to their channels using concatenation
	assign {VGA_R, VGA_G, VGA_B} = colorOut;


endmodule