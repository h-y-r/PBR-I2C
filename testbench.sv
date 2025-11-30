`timescale 1ns/1ps
module testbench;
	wire SDA, SCL;
    logic clk = 0;
    always #1 clk =~clk; //500MHz
  
    I2C_generic i2c(.SDA (SDA), .SCL (SCL));
    I2C_driver i2c_driv(.SDA(SDA), .SCL(SCL), .clk(clk));
  
  	initial begin
	  $dumpfile("dump.vcd");
      $dumpvars(0,testbench);
      #50
      $finish(0);
    end   
  
endmodule