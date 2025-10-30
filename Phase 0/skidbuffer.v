//////////////////////////////////////////////////////////////////////////////////
// Module Name: skidbuffer
// Description: implementation of skid buffer / pipeline skid buffer with provided inferface.
// Additional Comments: pass-through when no backpressure; captures one-beat skid
//                      when ready_out drops late; guarantees no data loss/dup.
//
//////////////////////////////////////////////////////////////////////////////////

module skidbuffer #(
  parameter DATA_WIDTH = 32
)(
  input                   clk,
  input                   reset,      // synch, active-high

  // upstream (producer -> skid)
  input                   valid_in,
  output                  ready_in,
  input  [DATA_WIDTH-1:0] data_in,

  // downstream (skid -> consumer)
  output                  valid_out,
  input                   ready_out,
  output [DATA_WIDTH-1:0] data_out
);

  // one-entry skid register
  reg                    skid_valid;
  reg [DATA_WIDTH-1:0]   skid_data;

  wire bypass = (skid_valid == 1'b0);

  // downstream interface
  assign valid_out = skid_valid | valid_in;           // output valid if holding or live
  assign data_out  = skid_valid ? skid_data : data_in; // prefer skidded data

  // upstream backpressure (only ready if not holding skidded beat)
  assign ready_in  = (skid_valid == 1'b0);

  // seq control
  always @(posedge clk) begin
    if (reset) begin
      skid_valid <= 1'b0;
      skid_data  <= {DATA_WIDTH{1'b0}};
    end else begin
      // release skidded beat once downstream is ready
      if (ready_out)
        skid_valid <= 1'b0;

      // late stall capture: downstream not ready, we are bypassing, and input is valid
      if (!ready_out && bypass && valid_in) begin
        skid_valid <= 1'b1;
        skid_data  <= data_in;
      end
    end
  end
endmodule
