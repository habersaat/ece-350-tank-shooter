module MMIO (
    input wire clk,                        // System clock
    input wire reset,                      // Reset signal
    input wire [31:0] address,             // Address from the processor
    input wire readEn,                     // Read enable signal
    output reg [31:0] readData,            // Data to send back to the processor
    input [10:1] JD,                       // Controller inputs JD
    input [10:1] JC                        // Controller inputs JC
);

    // Define base addresses for each controller input
    localparam P1_CONTROLLER1_DOWN_ADDR  = 32'hFFFF0000;
    localparam P1_CONTROLLER1_RIGHT_ADDR = 32'hFFFF0004;
    localparam P1_CONTROLLER1_LEFT_ADDR  = 32'hFFFF0008;
    localparam P1_CONTROLLER1_UP_ADDR    = 32'hFFFF000C;

    localparam P1_CONTROLLER2_DOWN_ADDR  = 32'hFFFF0010;
    localparam P1_CONTROLLER2_RIGHT_ADDR = 32'hFFFF0014;
    localparam P1_CONTROLLER2_LEFT_ADDR  = 32'hFFFF0018;
    localparam P1_CONTROLLER2_UP_ADDR    = 32'hFFFF001C;

    localparam P2_CONTROLLER1_DOWN_ADDR  = 32'hFFFF0020;
    localparam P2_CONTROLLER1_RIGHT_ADDR = 32'hFFFF0024;
    localparam P2_CONTROLLER1_LEFT_ADDR  = 32'hFFFF0028;
    localparam P2_CONTROLLER1_UP_ADDR    = 32'hFFFF002C;

    localparam P2_CONTROLLER2_DOWN_ADDR  = 32'hFFFF0030;
    localparam P2_CONTROLLER2_RIGHT_ADDR = 32'hFFFF0034;
    localparam P2_CONTROLLER2_LEFT_ADDR  = 32'hFFFF0038;
    localparam P2_CONTROLLER2_UP_ADDR    = 32'hFFFF003C;

    // Extract individual controller signals
    wire P1_CONTROLLER1_DOWN = JD[7];
    wire P1_CONTROLLER1_RIGHT = JD[10];
    wire P1_CONTROLLER1_LEFT = JD[9];
    wire P1_CONTROLLER1_UP = JD[8];

    wire P1_CONTROLLER2_DOWN = JD[4];
    wire P1_CONTROLLER2_RIGHT = JD[3];
    wire P1_CONTROLLER2_LEFT = JD[2];
    wire P1_CONTROLLER2_UP = JD[1];

    wire P2_CONTROLLER1_DOWN = JC[10];
    wire P2_CONTROLLER1_RIGHT = JC[8];
    wire P2_CONTROLLER1_LEFT = JC[7];
    wire P2_CONTROLLER1_UP = JC[9];

    wire P2_CONTROLLER2_DOWN = JC[4];
    wire P2_CONTROLLER2_RIGHT = JC[3];
    wire P2_CONTROLLER2_LEFT = JC[2];
    wire P2_CONTROLLER2_UP = JC[1];

    // Respond to read requests
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            readData <= 32'b0; // Reset the read data
        end else if (readEn) begin
            // Check which address is being accessed
            case (address)
                P1_CONTROLLER1_DOWN_ADDR: begin
                    readData <= {31'b0, P1_CONTROLLER1_DOWN};
                end
                P1_CONTROLLER1_RIGHT_ADDR: begin
                    readData <= {31'b0, P1_CONTROLLER1_RIGHT};
                end
                P1_CONTROLLER1_LEFT_ADDR: begin
                    readData <= {31'b0, P1_CONTROLLER1_LEFT};
                end
                P1_CONTROLLER1_UP_ADDR: begin
                    readData <= {31'b0, P1_CONTROLLER1_UP};
                end

                P1_CONTROLLER2_DOWN_ADDR: begin
                    readData <= {31'b0, P1_CONTROLLER2_DOWN};
                end
                P1_CONTROLLER2_RIGHT_ADDR: begin
                    readData <= {31'b0, P1_CONTROLLER2_RIGHT};
                end
                P1_CONTROLLER2_LEFT_ADDR: begin
                    readData <= {31'b0, P1_CONTROLLER2_LEFT};
                end
                P1_CONTROLLER2_UP_ADDR: begin
                    readData <= {31'b0, P1_CONTROLLER2_UP};
                end

                P2_CONTROLLER1_DOWN_ADDR: begin
                    readData <= {31'b0, P2_CONTROLLER1_DOWN};
                end
                P2_CONTROLLER1_RIGHT_ADDR: begin
                    readData <= {31'b0, P2_CONTROLLER1_RIGHT};
                end
                P2_CONTROLLER1_LEFT_ADDR: begin
                    readData <= {31'b0, P2_CONTROLLER1_LEFT};
                end
                P2_CONTROLLER1_UP_ADDR: begin
                    readData <= {31'b0, P2_CONTROLLER1_UP};
                end

                P2_CONTROLLER2_DOWN_ADDR: begin
                    readData <= {31'b0, P2_CONTROLLER2_DOWN};
                end
                P2_CONTROLLER2_RIGHT_ADDR: begin
                    readData <= {31'b0, P2_CONTROLLER2_RIGHT};
                end
                P2_CONTROLLER2_LEFT_ADDR: begin
                    readData <= {31'b0, P2_CONTROLLER2_LEFT};
                end
                P2_CONTROLLER2_UP_ADDR: begin
                    readData <= {31'b0, P2_CONTROLLER2_UP};
                end

                default: begin
                    readData <= 32'b0; // Default to 0 for unmapped addresses
                end
            endcase
        end
    end
endmodule
