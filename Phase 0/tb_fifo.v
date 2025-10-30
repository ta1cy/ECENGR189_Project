`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module Name: tb_fifo
// Description: testbench for synchronous fifo (fifo.v)
//              module 1 pipes data into FIFO until it is full
//              module 2 reads data from FIFO when it is full
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module tb_fifo;
  parameter DEPTH = 8;
  parameter WIDTH = 8;

  reg  clk, reset;
  reg  write_en, read_en;
  reg  [WIDTH-1:0] write_data;
  wire [WIDTH-1:0] read_data;
  wire full, empty;

  fifo #(.WIDTH(WIDTH), .DEPTH(DEPTH)) dut (
    .clk(clk),
    .reset(reset),
    .write_en(write_en),
    .write_data(write_data),
    .read_en(read_en),
    .read_data(read_data),
    .full(full),
    .empty(empty)
  );

  // 100 mhz clock
  initial clk = 1'b0;
  always #5 clk = ~clk;

  // setup data queue
  reg [WIDTH-1:0] exp_q [0:DEPTH-1];
  integer wr_idx, rd_idx;

  // push one item (write on the rising edge)
  task push;
    input [WIDTH-1:0] d;
    begin
      @(posedge clk);
      write_en   = 1'b1;
      write_data = d;
      read_en    = 1'b0;
      @(posedge clk);
      write_en   = 1'b0;
    end
  endtask

  // pop one item (synchronous read_data; sample on negedge)
  task pop;
    begin
      @(posedge clk);
      read_en  = 1'b1;
      write_en = 1'b0;
      @(posedge clk);
      read_en  = 1'b0;
    end
  endtask

  initial begin
    // init
    write_en = 1'b0;
    read_en  = 1'b0;
    write_data = {WIDTH{1'b0}};
    wr_idx = 0;
    rd_idx = 0;

    // reset
    reset = 1'b1;
    repeat (2) @(posedge clk);
    reset = 1'b0;

    // ===================== module 1: write until full =====================
    $display("[TB] module 1: writing until full");
    while (full == 1'b0) begin
      exp_q[wr_idx] = wr_idx[WIDTH-1:0];
      push(wr_idx[WIDTH-1:0]);
      wr_idx = wr_idx + 1;
    end
    $display("[TB] fifo reported full after %0d writes", wr_idx);
    if (wr_idx !== DEPTH) begin
      $display("ERROR: expected to fill exactly DEPTH=%0d entries, got %0d", DEPTH, wr_idx);
      $stop;
    end

    // guard: ensure we start reading only when full
    if (!full) begin
      $display("ERROR: module 2 started before fifo full");
      $stop;
    end

    // ===================== module 2: read until empty =====================
    $display("[TB] module 2: reading until empty");
    while (empty == 1'b0) begin
      pop();
      @(negedge clk); // read_data registered on read cycle
      if (read_data !== exp_q[rd_idx]) begin
        $display("ERROR: mismatch at rd_idx=%0d: got %0d expected %0d",
                 rd_idx, read_data, exp_q[rd_idx]);
        $stop;
      end
      rd_idx = rd_idx + 1;
    end

    if (rd_idx !== wr_idx) begin
      $display("ERROR: lost or extra items: wrote %0d, read %0d", wr_idx, rd_idx);
      $stop;
    end

    $display("[TB] fifo module 1 + module 2 tests passed");
    #20 $finish;
  end
endmodule