// INTERFACE DECLARATION BLOCK
interface alu_intf1(input bit clk);

        logic rst;
        logic [31:0] operand_a;
        logic [31:0] operand_b;
        logic [4:0] opcode;
        logic [31:0] result;
        logic zero;
        logic carry;

        clocking cb @(posedge clk);
                default input #1ns output #1ns;
                output opcode, operand_a, operand_b, rst;
                input result, carry, zero;
        endclocking

        modport DUT_MP (
                input clk, opcode, operand_a, operand_b, rst,
                output result, carry, zero
        );

        modport TB_MP (
                clocking cb
        );

endinterface


// DESIGN UNDER TEST: MODULE ALU_DUT
module alu_dut(
        alu_intf1.DUT_MP vif
);

        logic [31:0] next_result;
        logic        next_carry;
        logic        next_zero;
        logic [32:0] temp_sum;

        logic [31:0] result_reg;
        logic        carry_reg;
        logic        zero_reg;

        // COMBINATIONAL LOGIC PROCESSING LAYER
always_comb begin
                next_result = 32'b0;
                next_carry  = 1'b0;
                next_zero   = 1'b0;
                temp_sum    = 33'b0;

                case(vif.opcode)
                        // Arithmetic Operators
                        5'b00000: begin // Addition
                                temp_sum    = vif.operand_a + vif.operand_b;
                                next_result = temp_sum[31:0];
                                next_carry  = temp_sum[32];
                        end
                        5'b00001: begin // Subtraction
                                next_result = vif.operand_a - vif.operand_b;
                                next_carry  = (vif.operand_a < vif.operand_b);
                        end
                        5'b00010: begin // Multiplication
                                next_result = vif.operand_a * vif.operand_b;
                        end
                        5'b00011: begin // Division
                                if(vif.operand_b != 0) begin
                                        next_result = vif.operand_a / vif.operand_b;
                                end
                        end

                        // Logical Operators
                        5'b00100: begin // Logical AND
                                next_result = {31'b0, (vif.operand_a && vif.operand_b)};
                        end
                        5'b00101: begin // Logical OR
                                next_result = {31'b0, (vif.operand_a || vif.operand_b)};
                        end
                        5'b00110: begin // Logical XOR
                                next_result = {31'b0, (vif.operand_a ^^ vif.operand_b)};
                        end
                        5'b00111: begin // Logical NOT
                                next_result = {31'b0, (!vif.operand_a)};
                        end

                        // Comparison & Shift Operators
                        5'b01000: begin // Equality Verification
                                next_result = {31'b0, (vif.operand_a == vif.operand_b)};
                        end
                        5'b01001: begin // Less Than Verification
                                next_result = {31'b0, (vif.operand_a < vif.operand_b)};
                        end
                        5'b01010: begin // Greater Than Verification
                                next_result = {31'b0, (vif.operand_a > vif.operand_b)};
                        end
                        5'b01011: begin // Logical Left Shift 
                                next_result = vif.operand_a << vif.operand_b;
                        end
                        5'b01100: begin // Logical Right Shift 
                                next_result = vif.operand_a >> vif.operand_b;
                        end

                        // Bitwise Operators
                        5'b01101: begin // Bitwise AND
                                next_result = vif.operand_a & vif.operand_b;
                        end
                        5'b01110: begin // Bitwise OR
                                next_result = vif.operand_a | vif.operand_b;
                        end
                        5'b01111: begin // Bitwise NOT
                                next_result = ~vif.operand_a;
                        end
                        5'b10000: begin // Bitwise XOR
                                next_result = vif.operand_a ^ vif.operand_b;
                        end

                        default: next_result = 32'b0;
                endcase
               next_zero = (next_result == 32'b0);
        end

        always_ff @(posedge vif.clk or posedge vif.rst) begin
                if(vif.rst) begin
                        result_reg <= 32'b0;
                        carry_reg  <= 1'b0;
                        zero_reg   <= 1'b0;
                end
                else begin
                        result_reg <= next_result;
                        carry_reg  <= next_carry;
                        zero_reg   <= next_zero;
                end
        end

        assign vif.result = result_reg;
        assign vif.carry  = carry_reg;
        assign vif.zero   = zero_reg;

endmodule
