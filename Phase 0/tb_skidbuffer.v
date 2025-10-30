`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module Name: tb_skidbuffer
// Description: testbench for skid buffer / pipeline skid buffer (skidbuffer.v)
//              verifies correct pass-through behavior and one-beat skid capture
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module tb_skidbuffer;
  parameter DATA_WIDTH  = 8;
  parameter TOTAL_BEATS = 20;

  reg                   clk, reset;
  reg                   valid_in;
  wire                  ready_in;
  reg  [DATA_WIDTH-1:0] data_in;

  wire                  valid_out;
  reg                   ready_out;
  wire [DATA_WIDTH-1:0] data_out;

  skidbuffer #(.DATA_WIDTH(DATA_WIDTH)) dut (
    .clk(clk),
    .reset(reset),
    .valid_in(valid_in),
    .ready_in(ready_in),
    .data_in(data_in),
    .valid_out(valid_out),
    .ready_out(ready_out),
    .data_out(data_out)
  );

  // 100 mhz clock
  initial clk = 1'b0;
  always #5 clk = ~clk;

  // upstream producer
  integer send_cnt;
  always @(posedge clk) begin
    if (reset) begin
      valid_in <= 1'b0;
      data_in  <= {DATA_WIDTH{1'b0}};
      send_cnt <= 0;
    end else begin
      if (send_cnt < TOTAL_BEATS) begin
        valid_in <= 1'b1;
        data_in  <= send_cnt[DATA_WIDTH-1:0];
        if (ready_in) send_cnt <= send_cnt + 1;
      end else begin
        valid_in <= 1'b0;
      end
    end
  end

  // downstream consumer
  // pattern: ready asserted for 4 cycles, then deasserted for 3 cycles
  integer cyc;
  always @(posedge clk) begin
    if (reset) begin
      cyc <= 0;
      ready_out <= 1'b0;
    end else begin
      cyc <= cyc + 1;
      if ((cyc % 7) < 4)
        ready_out <= 1'b1; // ready
      else
        ready_out <= 1'b0; // backpressure
    end
  end

  // scoreboard
  integer exp_next, recv_cnt;
  always @(posedge clk) begin
    if (reset) begin
      exp_next <= 0;
      recv_cnt <= 0;
    end else if (valid_out && ready_out) begin
      // check ordering and data integrity
      if (data_out !== exp_next[DATA_WIDTH-1:0]) begin
        $display("ERROR @%0t: got %0d expected %0d",
                 $time, data_out, exp_next);
        $stop;
      end
      exp_next <= exp_next + 1;
      recv_cnt <= recv_cnt + 1;
    end
  end

  // test control
  initial begin
    reset     = 1'b1;
    valid_in  = 1'b0;
    ready_out = 1'b0;
    data_in   = {DATA_WIDTH{1'b0}};

    // reset for a few cycles
    repeat (3) @(posedge clk);
    reset = 1'b0;

    // wait until all beats received
    wait (recv_cnt == TOTAL_BEATS);
    $display("[TB] received all %0d beats properly", TOTAL_BEATS);

    #50 $finish;
  end
endmodule
