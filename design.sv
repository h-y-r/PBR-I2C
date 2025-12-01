`timescale 1ns/1ps
module I2C_generic (inout SDA, input SCL, input clk);
  parameter addr = 7'b1;
  reg[7:0] mem;
  reg[6:0] addr_cnt;
  logic start_flag = 0;
  logic listen_data = 0;
  logic sda_prev = 0;
  logic scl_prev = 0;
  //logic sda_local = 0;
  //assign SDA = sda_local;
  int i = 6;
  always_ff @(posedge clk) begin
    if ((sda_prev == 1'b1) && (SDA == 1'b0) && (SCL==1'b1) && (scl_prev == 1'b1)) begin
      start_flag <= 1'b1;
    end 
  end
  always_ff @(negedge clk) begin
    sda_prev <= SDA;
    scl_prev <= SCL;
  end //scl prev potrzebne zeby nie dzialal start jak w tym samym momencie sie zmienia SDA i SCL, ale w razie co mozna chyba to wywalic
  
  
  
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

module I2C_driver#(parameter int prsc = 4,
                   parameter int delay = 2) //min delay = 2 - zeby reszta mogla zareagowac na zmiany (musi minac pelny okres szybkiego clk)
  (inout SDA, output SCL, input clk);
  logic scl_local = 0;
  logic sda_local = 1;
  reg[6:0] addr_obj = 7'b1011101;
  int prsc_cnt = 0;
  
  assign SCL = scl_local;
  assign SDA = sda_local;
  
  task send_addr;
    begin
      @(posedge scl_local);
        #delay sda_local = 0; //start condition
      
      for (int i = 6; i >= 0; i--) begin
        @(negedge scl_local);
        #delay sda_local <= addr_obj[i]; //wysylanie bitow adresu
      end
    end
  endtask
  
  initial begin
    #4
    send_addr;
  end
  
  
  always @(posedge clk) begin
    prsc_cnt++;
    if(prsc_cnt == prsc) begin
      scl_local = ~scl_local;
      prsc_cnt = 0;
    end
  end
  
endmodule