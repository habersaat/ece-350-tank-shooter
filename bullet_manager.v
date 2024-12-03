module bullet_manager(
    input wire clk,
    input wire reset,
    input wire spawn_bullet,        // Signal to spawn a new bullet
    input wire [8:0] new_x_position, // New bullet's initial x position
    input wire [8:0] new_y_position, // New bullet's initial y position
    input wire [4:0] new_TTL,       // Initial TTL for the new bullet
    input wire [2:0] new_direction, // Direction for the new bullet
    input wire [7:0] base_address,  // Base address for bullets in RAM
    input wire [31:0] ram_data_in,  // Data read from RAM
    output reg [31:0] ram_data_out, // Data to write to RAM
    output reg [7:0] ram_address,   // Address to read/write from RAM
    output reg ram_write_enable     // Write enable signal for RAM
);
    // Internal registers for tracking bullet state
    reg [7:0] current_bullet_index = 0; // Index of the current bullet being processed
    reg [31:0] bullet_data;            // Temporary storage for a bullet's data
    reg is_active;
    reg [8:0] x_position, y_position;
    reg [4:0] TTL;
    reg [2:0] direction;

    // Sequential logic to process bullets
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            // Reset all internal state
            current_bullet_index <= 0;
        end else if (spawn_bullet) begin
            // Spawn a new bullet
            ram_address <= base_address + current_bullet_index;
            ram_data_out <= {new_x_position, new_y_position, new_TTL, new_direction, 1'b1}; // Pack bullet data
            ram_write_enable <= 1;
            current_bullet_index <= current_bullet_index + 1;
        end else begin
            // Update existing bullets
            ram_address <= base_address + current_bullet_index;
            bullet_data <= ram_data_in;

            // Unpack bullet data
            x_position <= bullet_data[31:23];
            y_position <= bullet_data[22:14];
            TTL <= bullet_data[13:9];
            direction <= bullet_data[8:6];
            is_active <= bullet_data[5];

            // Update active bullets
            if (is_active) begin
                case (direction)
                    3'b000: y_position <= y_position - 1; // Up
                    3'b001: begin y_position <= y_position - 1; x_position <= x_position + 1; end // Up/Right
                    3'b010: x_position <= x_position + 1; // Right
                    3'b011: begin y_position <= y_position + 1; x_position <= x_position + 1; end // Down/Right
                    3'b100: y_position <= y_position + 1; // Down
                    3'b101: begin y_position <= y_position + 1; x_position <= x_position - 1; end // Down/Left
                    3'b110: x_position <= x_position - 1; // Left
                    3'b111: begin y_position <= y_position - 1; x_position <= x_position - 1; end // Up/Left
                endcase

                // Decrement TTL
                TTL <= TTL - 1;
                if (TTL == 0) begin
                    is_active <= 0; // Deactivate bullet
                end

                // Pack updated bullet data
                ram_data_out <= {x_position, y_position, TTL, direction, is_active};
                ram_write_enable <= 1;
            end

            // Move to the next bullet
            current_bullet_index <= current_bullet_index + 1;
        end
    end
endmodule
