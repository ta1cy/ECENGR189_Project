`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module Name: tb_prioritydecoder
// Description: testbench for prioritydecoder
//              verifies valid and highest-priority output
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module tb_prioritydecoder;
  parameter WIDTH = 4;
  localparam OUTW = (WIDTH <= 1) ? 1 : clog2(WIDTH);

  reg  [WIDTH-1:0] in;
  wire [OUTW-1:0]  out;
  wire valid;

  prioritydecoder #(.WIDTH(WIDTH)) dut (
    .in(in),
    .out(out),
    .valid(valid)
  );

  function integer clog2;
    input integer value;
    integer i;
    begin
      clog2 = 0;
      for (i = value - 1; i > 0; i = i >> 1)
        clog2 = clog2 + 1;
    end
  endfunction

  integer i;

  initial begin
    $display("[TB] prioritydecoder start (WIDTH=%0d, OUTW=%0d)", WIDTH, OUTW);

    in = {WIDTH{1'b0}}; #5;
    if (valid !== 1'b0)
      $display("ERROR: valid should be 0 when in=0");

    for (i = 0; i < WIDTH; i = i + 1) begin
      in = (1'b1 << i); #5;
      if (!valid)
        $display("ERROR: valid=0 for in=%b", in);
      if (out !== i[OUTW-1:0])
        $display("ERROR: out=%0d exp=%0d for in=%b", out, i, in);
      else
        $display("[TB] PASS single-bit in=%b -> out=%0d", in, out);
    end

    in = 4'b1010; #5; // expect 3
    if (out !== 2'b11)
      $display("ERROR: expected 3 (2'b11) got %0d (in=%b)", out, in);

    in = 4'b0110; #5; // expect 2
    if (out !== 2'b10)
      $display("ERROR: expected 2 (2'b10) got %0d (in=%b)", out, in);

    $display("[TB] prioritydecoder finished");
    #10 $finish;
  end
endmodule
