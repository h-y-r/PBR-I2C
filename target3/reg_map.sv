
module reg_map (
  input  logic       clk,
  input  logic       rst_n,
  input  logic [7:0] addr,
  input  logic [7:0] wdata,
  input  logic       wr_en_wdata,
  output logic [7:0] rdata,
  output logic [7:0] register_0,
  output logic [7:0] register_1,
  output logic [7:0] register_2,
  output logic [7:0] register_3,
  output logic [7:0] register_4,
  output logic [7:0] register_5,
  output logic [7:0] register_6,
  output logic [7:0] register_7,
  output logic [7:0] register_8,
  output logic [7:0] register_9,
  output logic [7:0] register_10,
  output logic [7:0] register_11,
  output logic [7:0] register_12,
  output logic [7:0] register_13,
  output logic [7:0] register_14,
  output logic [7:0] register_15
);
  
  parameter MAX_ADDRESS = 15; // 4 total addresses, including zero
  
  logic [7:0] registers [MAX_ADDRESS:0];
  logic wr_en_wdata_hold;
  logic wr_en_wdata_fedge;
  
  always_ff @ (posedge clk, negedge rst_n)
    if (!rst_n) wr_en_wdata_hold <= 1'b0;
    else        wr_en_wdata_hold <= wr_en_wdata;
    
  assign wr_en_wdata_fedge = wr_en_wdata_hold && (!wr_en_wdata);
  
  // a compact method to capture writes
  integer i;
  always_ff @(posedge clk, negedge rst_n)
    if (!rst_n)      for (i=0; i<=MAX_ADDRESS; i=i+1) registers[i]    <= 8'h00;
    else if (wr_en_wdata_fedge)                       registers[addr] <= wdata;
  
  // some FPGAs explode when unexpected addresses are used
  assign rdata = (addr <= MAX_ADDRESS) ? registers[addr] : 8'd0;
 
 // this is just renaming the registers bits to custom names
  always_comb begin
    register_0 = registers[0];
    register_1 = registers[1];
    register_2 = registers[2];
    register_3 = registers[3];
    register_4 = registers[4];
    register_5 = registers[5];
    register_6 = registers[6];
    register_7 = registers[7];
    register_8 = registers[8];
    register_9 = registers[9];
    register_10 = registers[10];
    register_11 = registers[11];
    register_12 = registers[12];
    register_13 = registers[13];
    register_14 = registers[14];
    register_15 = registers[15];
  end
 
endmodule