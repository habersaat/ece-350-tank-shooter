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

	// Boolean for whether x,y in bullet:
	reg isBulletActive;
	integer i;

	// Boolean for whether x,y in any bullet
    reg isBulletActive;
    integer i;

    always @(*) begin
        isBulletActive = 0;
        for (i = 0; i < MAX_BULLETS; i = i + 1) begin
            if (bulletManager.active[i] && 
                (x >= bulletManager.x_positions[i] && x < bulletManager.x_positions[i] + BULLET_SIZE) &&
                (y >= bulletManager.y_positions[i] && y < bulletManager.y_positions[i] + BULLET_SIZE)) begin
                isBulletActive = 1;
            end
        end
    end

	// BulletRAM for managing bullet data
    wire [31:0] ram_data_in;
    wire [31:0] ram_data_out;
    wire [7:0] ram_address;
    wire ram_write_enable;
    wire ram_read_enable = 1'b1; // Always enable reading

    BulletRAM #(
        .DATA_WIDTH(32),
        .ADDRESS_WIDTH(8),
        .DEPTH(MAX_BULLETS)
    ) BulletRAMInstance (
        .clk(clk),
        .wEn(ram_write_enable),
        .readEn(ram_read_enable),
        .addr(ram_address),
        .dataIn(ram_data_out),
        .dataOut(ram_data_in)
    );

    // BULLET LOGIC
    wire [8:0] bullet_x_position = currX + (SPRITE_SIZE / 2);
    wire [10:0] bullet_y_position = currY + (SPRITE_SIZE / 2);
    wire [4:0] bullet_TTL = 5'd20; // Lifespan of 20 frames
    wire [2:0] bullet_direction = 3'b100; // Example: Down

    wire SHOOT = BTNC; // Button C to shoot

    bullet_manager bulletManager (
        .clk(clk),
        .reset(reset),
        .spawn_bullet(SHOOT),
        .new_x_position(bullet_x_position),
        .new_y_position(bullet_y_position),
        .new_TTL(bullet_TTL),
        .new_direction(bullet_direction),
        .base_address(8'h00),
        .ram_data_in(ram_data_in),
        .ram_data_out(ram_data_out),
        .ram_address(ram_address),
        .ram_write_enable(ram_write_enable)
    );
	
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
		SPRITE_SIZE = 64,   // Size of the sprite
		BULLET_SIZE = 8,	// Size of the bullet
        MAX_BULLETS = 256;	// Maximum number of bullets

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
	wire [11:0] bulletColorData = 12'hF00; // Red color for bullets
	
	assign colorOut = active ? 
    	(isInSquare ? spriteColorData : 
     	(isBulletActive ? bulletColorData : colorData)) : 
    	12'd0; // Black when not active

	// Quickly assign the output colors to their channels using concatenation
	assign {VGA_R, VGA_G, VGA_B} = colorOut;


endmodule