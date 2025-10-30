//////////////////////////////////////////////////////////////////////////////////
// Module Name: prioritydecoder
// Description: implementation of a priority decoder with provided interface
// Additional Comments: outputs index of highest-order '1' bit and valid flag
//
//////////////////////////////////////////////////////////////////////////////////

module prioritydecoder #(
  parameter WIDTH = 4
)(
  input  [WIDTH-1:0] in,
  output reg [$clog2(WIDTH)-1:0] out,
  output reg valid
);
  integer i;
  reg found;

  always @* begin
    valid = 1'b0;
    found = 1'b0;
    out   = {($clog2(WIDTH)){1'b0}};
    for (i = WIDTH-1; i >= 0; i = i - 1) begin
      if (in[i] && !found) begin
        valid = 1'b1;
        out   = i[$clog2(WIDTH)-1:0];
        found = 1'b1;
      end
    end
  end
endmodule
