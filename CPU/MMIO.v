module MMIO (
    input wire clk,                        // System clock
    input wire reset,                      // Reset signal
    input wire [31:0] address,             // Address from the processor
    input wire readEn,                     // Read enable signal
    output reg [31:0] readData,            // Data to send back to the processor
    input [10:1] JD                        // Controller inputs
);

    // Define base addresses for each controller
    localparam CONTROLLER1_BASE_ADDR = 32'hFFFF0000;
    localparam CONTROLLER2_BASE_ADDR = 32'hFFFF0004;

    // Extract individual controller signals
    wire controller1_down = JD[4];
    wire controller1_right = JD[3];
    wire controller1_left = JD[2];
    wire controller1_up = JD[1];

    wire controller2_down = JD[7];
    wire controller2_right = JD[10];
    wire controller2_left = JD[9];
    wire controller2_up = JD[8];

    // Respond to read requests
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            readData <= 32'b0; // Reset the read data
        end else if (readEn) begin
            // Check which address is being accessed
            case (address)
                CONTROLLER1_BASE_ADDR: begin
                    readData <= {28'b0, controller1_down, controller1_right, controller1_left, controller1_up};
                end
                CONTROLLER2_BASE_ADDR: begin
                    readData <= {28'b0, controller2_down, controller2_right, controller2_left, controller2_up};
                end
                default: begin
                    readData <= 32'b0; // Default to 0 for unmapped addresses
                end
            endcase
        end
    end
endmodule