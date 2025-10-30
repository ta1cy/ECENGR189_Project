//////////////////////////////////////////////////////////////////////////////////
// Module Name: fifo2
// Description: modified synchronous FIFO into circular buffer
// Additional Comments: careful when checking if the FIFO is full. There could be underflow/overflow bugs!
// 
//////////////////////////////////////////////////////////////////////////////////

module fifo2 #(
  parameter WIDTH = 32, // note, verilog can't implement logic, so use parameter instead
  parameter DEPTH = 8
)(
  input  clk,
  input  reset, // synch, active-high
  input  write_en,
  input  [WIDTH-1:0] write_data,
  input  read_en,
  output reg [WIDTH-1:0] read_data,
  output reg full,
  output reg empty
);
  // integer ceil(log2()) for ptr width
  function integer clog2;
    input integer value;
    integer i;
    begin
      clog2 = 0;
      for (i = value - 1; i > 0; i = i >> 1) clog2 = clog2 + 1;
    end
  endfunction

  localparam addr_width = (DEPTH <= 1) ? 1 : clog2(DEPTH);
  reg [WIDTH-1:0] mem [0:DEPTH-1];
  reg [addr_width-1:0] wptr, rptr;
  // increment with wrap
  function [addr_width-1:0] inc_wrap;
    input [addr_width-1:0] v;
    begin
      if (v == DEPTH-1) inc_wrap = {addr_width{1'b0}};
      else              inc_wrap = v + {{(addr_width-1){1'b0}}, 1'b1};
    end
  endfunction

  wire [addr_width-1:0] wptr_nxt = inc_wrap(wptr);
  wire [addr_width-1:0] rptr_nxt = inc_wrap(rptr);
  // get status from pointers
  wire empty_w = (wptr == rptr);
  wire full_w = (wptr_nxt == rptr);
  // qualified operations (allow write when a same-cycle read frees space)
  wire read_req = read_en  && !empty_w;
  wire write_req = write_en && (!full_w || read_req);

  // flags (combinational)
  always @* begin
    empty = empty_w;
    full = full_w;
  end
  // seq behavior
  always @(posedge clk) begin
    if (reset) begin
      wptr <= {addr_width{1'b0}};
      rptr <= {addr_width{1'b0}};
      read_data <= {WIDTH{1'b0}};
    end else begin
      // read first (read_data registered)
      if (read_req) begin
        read_data <= mem[rptr];
        rptr <= rptr_nxt;
      end
      // then write
      if (write_req) begin
        mem[wptr] <= write_data;
        wptr <= wptr_nxt;
      end
    end
  end
endmodule

