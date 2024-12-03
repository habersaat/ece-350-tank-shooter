module regfile (
	clock,
	ctrl_writeEnable, ctrl_reset, ctrl_writeReg,
	ctrl_readRegA, ctrl_readRegB, data_writeReg,
	data_readRegA, data_readRegB
);

	// Define the inputs and outputs
	input clock, ctrl_writeEnable, ctrl_reset;
	input [4:0] ctrl_writeReg, ctrl_readRegA, ctrl_readRegB;
	input [31:0] data_writeReg;
	output [31:0] data_readRegA, data_readRegB;

	// 32 registers, each 32 bits
    wire [31:0] registers [31:0];

	// Decoder for the read registers
	wire [31:0] read_enable_A; // One-hot enable for read register A
    wire [31:0] read_enable_B; // One-hot enable for read register B
    assign read_enable_A = 1 << ctrl_readRegA;
    assign read_enable_B = 1 << ctrl_readRegB;

	// Decoder for the write register
	wire [31:0] write_enable;  // One-hot write enable signals from decoder
	assign write_enable = ctrl_writeEnable << ctrl_writeReg;

	// Create 32 registers
    genvar i;
    generate
        for (i = 1; i < 32; i = i + 1) begin : register_block
            register reg_inst (
                .clock(clock),
                .reset(ctrl_reset),
                .in_enable(write_enable[i]),  // Write to register only if enabled by the decoder
                .D(data_writeReg),            // Write data
                .Q(registers[i])              // Output data
            );

			// Tri-state buffer for data_readRegA and data_readRegB
            assign data_readRegA = read_enable_A[i] ? registers[i] : 32'bz;
            assign data_readRegB = read_enable_B[i] ? registers[i] : 32'bz;
        end
    endgenerate

	// Register 0 is hardwired to 0
    assign registers[0] = 32'b0;

	// Tri-state buffer for register 0 (since it is not in the loop)
    assign data_readRegA = read_enable_A[0] ? registers[0] : 32'bz;
    assign data_readRegB = read_enable_B[0] ? registers[0] : 32'bz;

endmodule
