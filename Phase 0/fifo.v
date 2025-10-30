//////////////////////////////////////////////////////////////////////////////////
// Module Name: fifo
// Description: implementation of a synchronous FIFO with provided interface
// Additional Comments: 
// 
//////////////////////////////////////////////////////////////////////////////////

module fifo #(
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
  reg [addr_width:0] count;

  wire read_req = read_en && (count != 0);
  wire write_req = write_en && ((count != DEPTH) || read_req);

  // set status
  always @* begin
    empty = (count == 0);
    full = (count == DEPTH);
  end
  // seq behavior
  always @(posedge clk) begin
    if (reset) begin
      wptr <= {addr_width{1'b0}};
      rptr <= {addr_width{1'b0}};
      count <= { (addr_width+1){1'b0} };
      read_data <= {WIDTH{1'b0}};
    end else begin
      if (read_req) begin // read_data registered
        read_data <= mem[rptr];
        if (rptr == DEPTH-1) rptr <= {addr_width{1'b0}};
        else rptr <= rptr + {{(addr_width-1){1'b0}},1'b1};
      end
      if (write_req) begin
        mem[wptr] <= write_data;
        if (wptr == DEPTH-1) wptr <= {addr_width{1'b0}};
        else wptr <= wptr + {{(addr_width-1){1'b0}},1'b1};
      end
      case ({write_req, read_req})
        2'b10: count <= count + {{addr_width{1'b0}},1'b1}; // write only
        2'b01: count <= count - {{addr_width{1'b0}},1'b1}; // read only
        default: count <= count; // has to be 00 or 11, update count
      endcase
    end
  end
endmodule
