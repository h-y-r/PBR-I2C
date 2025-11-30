`timescale 1ns/1ps
module I2C_generic (inout SDA, input SCL);
  parameter addr = 7'b1;
  reg[7:0] mem;
  reg[6:0] addr_cnt;
  logic start_flag = 0;
  logic sda_prev = 0;
  //logic sda_local = 0;
  //assign SDA = sda_local;
  int i = 6;
  
  always @(negedge SDA) begin
    if (SCL) begin
        start_flag = 1;
      $display("start flag jest 1");
    end
  end
  
  always @(posedge SCL) begin
  	if (start_flag) begin
      #1 addr_cnt[i] = SDA;
      i--;      
  	end
    if (i == -1) begin
    	start_flag = 0;
    	i = 6;
      $display("%0b", addr_cnt);
  	end
  end
     
//   initial begin
//     start_detect;
//   end
//   task addr_listen
//     begin
//       if (
//     end
//   endtask
  
endmodule

module I2C_driver (inout SDA, output SCL, input clk);
  logic scl_local = 0;
  logic sda_local = 1;
  reg[6:0] addr_obj = 7'b1011101;
  
  assign SCL = scl_local;
  assign SDA = sda_local;
  
  task send_addr;
    begin
      @(posedge scl_local);
      	#1 sda_local = 0; //start condition
      
      for (int i = 6; i >= 0; i--) begin
        @(negedge scl_local);
        #1 sda_local <= addr_obj[i]; //wysylanie bitow adresu
      end
    end
  endtask
  
  initial begin
    #4
    send_addr;
  end
  
  
  always @(posedge clk) begin
    scl_local = ~scl_local;
  end
  
endmodule