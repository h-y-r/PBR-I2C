`define DRIVER testbench.dv_i2c
`define TARGET testbench.tg_i2c
`define MAIL testbench.dv_i2c.tr_mailbox
`define RAND testbench.i2c_cfg
`define TRANS testbench.test_tr
`define TARGET_BITS testbench.tg_i2c.data_send //ostatnie do zmieniania, latwiej bedzie dla roznych targetow z definicja

import transaction_class::*;

module basic_test;

property GENERAL_CALL_IGNORE;
	@(posedge testbench.SCL)
	(`DRIVER.phase == M_GENERAL_CALL) //driver daje adres
	##0(testbench.SDA == 1'b0 [*8]) //00h - general call
	|=> (testbench.SDA == 1'b1); //nack - slave ignoruje
endproperty																							    

property GENERAL_CALL_RESET_AND_WRTIE;
	@(posedge testbench.SCL) //general call 8'b0 + ack + 00000110 + ack
	((`DRIVER.phase == M_GENERAL_CALL) && (`DRIVER.selected_call == RESET) && (`DRIVER.bit_idx == 0))  //driver daje adres
	|=> (testbench.SDA == 1'b0) //ack
endproperty

property GENERAL_CALL_WRTIE;
	@(posedge testbench.SCL) //general call 8'b0 + ack + 00000110 + ack
	((`DRIVER.phase == M_GENERAL_CALL) && (`DRIVER.selected_call == WRITE) && (`DRIVER.bit_idx == 0)) //driver daje adres
	|=>  (testbench.SDA == 1'b0) //ack
	//|=> (`TARGET.state !== 0); //nie reset slave
endproperty

property GENERAL_CALL_ILLEGAL;
	@(posedge testbench.SCL) //general call 8'b0 + ack + 00000000 + nack - nielegalny call				
	((`DRIVER.phase == M_GENERAL_CALL) && (`DRIVER.selected_call == ILLEGAL) && (`DRIVER.bit_idx == 0))  //driver daje adres
	|=> (testbench.SDA == 1'b1); //nack od slave
endproperty

property HARDWARE_GENERAL_CALL;
	@(posedge testbench.SCL) //general call 8'b0 + ack + 00000001 + nack 
	((`DRIVER.phase == M_GENERAL_CALL) && (`DRIVER.selected_call == HARDWARE) && (`DRIVER.bit_idx == 0))  //driver daje adres
	|=> (testbench.SDA == 1'b0) //nack od slave
endproperty

int NUM_TRANSACTIONS = testbench.NUM_TRANSACTIONS;

initial begin
	Transaction tr;

	`RAND = new();
	#100ns;
		if (!`RAND.randomize()) begin
		$error("blad");
	end

	`DRIVER.HIGH_PERIOD_SCL = `RAND.high_period;
	`DRIVER.LOW_PERIOD_SCL  = `RAND.low_period;
	`DRIVER.DATA_SETUP_TIME = `RAND.setup_time;
	`DRIVER.RAND_STOP_BIT = `RAND.rand_bit;
	`DRIVER.START_SETUP_TIME = `RAND.start_setup_time;
	`DRIVER.START_HOLD_TIME = `RAND.start_hold_time;
	`DRIVER.STOP_SETUP_TIME = `RAND.stop_setup_time;
	`DRIVER.DATA_HOLD_TIME = `DRIVER.LOW_PERIOD_SCL - `DRIVER.DATA_SETUP_TIME;	
	#100ns;

	for (int i = 0; i < NUM_TRANSACTIONS; i++) begin		
		`DRIVER.generalCalls(2'b00);
		#`DRIVER.BUFF_TIME
		`DRIVER.generalCalls(2'b01);
		#`DRIVER.BUFF_TIME
		`DRIVER.generalCalls(2'b10);
		#`DRIVER.BUFF_TIME
		`DRIVER.generalCalls(2'b11);
	#100ns;
	end
	$finish(0);
end


chk_generalCallIgnore : assert property(GENERAL_CALL_IGNORE) $display("chk_generalCallIgnore PASSED!");
		else $error("chk_generalCallIgnore FAILED!");	

chk_generalCallResetAndWrite : assert property(GENERAL_CALL_RESET_AND_WRTIE) $display("chk_generalCallResetAndWrite PASSED!");
		else $error("chk_generalCallResetAndWrite FAILED!");

chk_generalCallWrite : assert property(GENERAL_CALL_WRTIE) $display("chk_chk_generalCallWritePASSED!");
		else $error("chk_generalCallWrite FAILED!");	

chk_generalCallIllegal : assert property(GENERAL_CALL_ILLEGAL) $display("chk_generalCallIllegal PASSED!");
		else $error("chk_generalCallIllegal FAILED!");

chk_hardwareGeneralCall : assert property(HARDWARE_GENERAL_CALL) $display("chk_hardwareGeneralCall PASSED!");
		else $error("chk_hardwareGeneralCall FAILED!");	
		
endmodule
