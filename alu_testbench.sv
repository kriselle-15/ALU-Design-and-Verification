class alu_transaction;
        rand logic [4:0] opcode;
        rand logic [31:0] operand_a;
        rand logic [31:0] operand_b;

        logic [31:0] result;
        logic zero;
        logic carry;

        constraint randomize_opcode{
                opcode inside {[5'b00000 : 5'b10000]};
}

        constraint valid_operands{
                operand_a inside {[1:1000]};
        }
        constraint division_nonzero{
                if (opcode == 5'b00011){
                        operand_b inside {[1:1000]};
        }
        else {
                operand_b inside {[0:1000]};
}
}

        function void display(string name);
                $display("[%s] Opcode: 5'b%b  | Op1: %0d | Op2: %0d | Result: %0d | Carry: %0b | Zero: %b", name, opcode, operand_a, operand_b, result, carry, zero);
        endfunction
endclass

class alu_driver;
        virtual alu_intf1.TB_MP vif;

        function new(virtual alu_intf1.TB_MP vif);
                this.vif = vif;
        endfunction

        task drive_packet(alu_transaction trans);
                @(vif.cb);
                vif.cb.operand_a <= trans.operand_a;
                vif.cb.operand_b <= trans.operand_b;
                vif.cb.opcode    <= trans.opcode;
          @(vif.cb);

                trans.result = vif.cb.result;
                trans.zero   = vif.cb.zero;
                trans.carry  = vif.cb.carry;
        endtask
endclass

class alu_generator;
        alu_driver drv;

        function new(alu_driver drv);
                this.drv = drv;
        endfunction

        task run();
                alu_transaction current_trans;
                alu_transaction printing_trans;

                fork
                begin: track1
                        repeat(15) begin
                                current_trans = new();
                                if (!current_trans.randomize()) begin
                                        $fatal(1, "Randomization failed");
                                end

                                drv.drive_packet(current_trans);

                                if (printing_trans != null) begin
                                        printing_trans.result = current_trans.result;
                                        printing_trans.zero   = current_trans.zero;
                                        printing_trans.carry  = current_trans.carry;

                                        printing_trans.display("ALU VERIFICATION ENGINE !")
                                  ;
                                end

                                printing_trans = current_trans;
                        end

                        #10ns;

                        printing_trans.result = drv.vif.cb.result;
                        printing_trans.zero   = drv.vif.cb.zero;
                        printing_trans.carry  = drv.vif.cb.carry;

                        printing_trans.display("ALU VERIFICATION ENGINE !");

                end : track1

                begin: track2
                        #5000ns;
                        $display("Watchdog timer. Simulation took too long");
                        $finish;
                end : track2
                join_any

                disable fork;
        endtask
endclass

module tb_top;
  bit clk;
  always #5 clk = ~clk;

  alu_intf1 intf(clk);

  alu_dut dut (
    .vif(intf)
  );

  initial begin
    $dumpfile("dump.vcd");
    $dumpvars(0, tb_top);

    $display("Starting...");
    intf.rst = 1;
    #15;
    intf.rst = 0;

    begin
      alu_driver    drv;
      alu_generator gen;

      drv = new(intf.TB_MP);
gen = new(drv);

      gen.run();
    end

    $display("All random operations completed successfully!");
    $finish;
  end

endmodule
