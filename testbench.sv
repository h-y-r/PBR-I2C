`timescale 1ns/10ps

module testbench;
  tri1 SCL;
  tri1 SDA;
  pullup(SDA);
  pullup(SCL);

  logic clk;
  logic rst;

  initial clk = 0;
  always #10 clk = ~clk;
  
  target_I2C tg_i2c(
    .rst(rst),
    .clk(clk),
    .data_send(16'hDEAD), 
    .SDA_bidir(SDA),      
    .SCL_bidir(SCL),    
    .data_received()
  );
  
  driver_I2C dv_i2c(
    .clk(clk),
    .SDA(SDA),
    .SCL(SCL)
  );

//   I2C_Config i2c_cfg;
  
  initial begin
//     i2c_cfg = new();
//     if (!i2c_cfg.randomize()) begin
//       $error("blad");
//       $finish;
//     end
//     dv_i2c.HIGH_PERIOD_SCL = i2c_cfg.high_period;
//     dv_i2c.LOW_PERIOD_SCL  = i2c_cfg.low_period;
//     dv_i2c.DATA_SETUP_TIME = i2c_cfg.setup_time;
//     dv_i2c.RANDOM_STOP_BIT = i2c_cfg.rand_bit;
    
	$dumpfile("dump.vcd");
    $dumpvars(0,testbench);
    #10;
    rst = 1;    
    #10;     
    rst = 0; 
    #10;
    rst = 1;
    
    //dv_i2c.writeTransaction(7'b0000111, 8'b10101010);
	//dv_i2c.readTransaction(7'b0000111);
    dv_i2c.writeRandomStop(7'b0000111, 8'b10101010, 2);
	dv_i2c.genSCL();
	dv_i2c.writeTransaction(7'b0000111, 8'b10101010);
    //dv_i2c.genSCL();
    //dv_i2c.sendStop();
    //dv_i2c.genSCL();
    
    $display("Simulation Finished.");

    #100000
    $finish(0);
  end

endmodule
