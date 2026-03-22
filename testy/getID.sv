`define DRIVER testbench.dv_i2c
`define TARGET testbench.tg_i2c
`define MAIL testbench.dv_i2c.tr_mailbox
`define RAND testbench.dv_i2c.i2c_cfg
`define TRANS testbench.test_tr
`define TARGET_BITS testbench.tg_i2c.data_send //ostatnie do zmieniania, latwiej bedzie dla roznych targetow z definicja

import transaction_class::*;

module test;

property GET_DEVICE_ID;
	@(posedge testbench.SCL)
	(((`DRIVER.phase == M_DEVICE_ID) && (`DRIVER.bit_idx == BIT_ACK)) && (testbench.SDA == 1'b0))
	##[1:$]
	((`DRIVER.phase == M_SEND_ADDR_FOR_ID) && (`DRIVER.bit_idx == BIT_ACK)) |=> (testbench.SDA == 1'b0); //mozna jeszcze dodac, ale najpierw zobaczyc czy na to odpowie
endproperty


initial begin
	Transaction tr;

	RAND = new();
	if (!RAND.randomize()) begin
	$error("blad");
	end

	DRIVER.HIGH_PERIOD_SCL = RAND.high_period;
	DRIVER.LOW_PERIOD_SCL  = RAND.low_period;
	DRIVER.DATA_SETUP_TIME = RAND.setup_time;
	DRIVER.RAND_STOP_BIT = RAND.rand_bit;
	DRIVER.START_SETUP_TIME = RAND.start_setup_time;
	DRIVER.START_HOLD_TIME = RAND.start_hold_time;
	DRIVER.STOP_SETUP_TIME = RAND.stop_setup_time;
	DRIVER.DATA_HOLD_TIME = DRIVER.LOW_PERIOD_SCL - DRIVER.DATA_SETUP_TIME;	
	#100ns;
		
	getDeviceID(7'b0000111);
	
	#25us;
end

tst_getDeviceID: assert property (GET_DEVICE_ID) $display("chk_getDeviceID PASSED!");
		else $error("chk_getDeviceID FAILED!");	
		
end module
