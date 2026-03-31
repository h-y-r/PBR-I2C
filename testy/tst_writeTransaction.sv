`define DRIVER testbench.dv_i2c
`define TARGET testbench.tg_i2c
`define MAIL testbench.dv_i2c.tr_mailbox
`define RAND testbench.i2c_cfg
`define TRANS testbench.test_tr

import transaction_class::*;

module tst_writeTransaction;

// Deklaracje zmiennych
bit ACK_AFTER_BYTE;
bit ACK_AFTER_ADDR;
bit RW_BIT;
bit CLOCK_STRETCH;

event assert_chk_ackAfterByte;
event assert_chk_addressExists;
event assert_chk_RWBitWrite;
event assert_chk_clockStretch;

realtime stretch_time1;
realtime stretch_time2;

property ACK_AFTER_DATA;
	@(posedge testbench.SCL)
	(`DRIVER.phase == M_DATA_TX && (`DRIVER.bit_idx == 0))
	|->
	(`DRIVER.ack_got == 1'b1);
endproperty	

initial begin
	Transaction tr;

	`RAND = new();
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
	tr = new(
        .addr(7'b0000111), 
        .rwSet(0), 
        .data_to_send({8'b10101010, 8'b11100011})
    );
	
	`MAIL.put(tr);

	wait (`DRIVER.phase == M_ACK_ADDR);
	RW_BIT = (!`TARGET.rw);
	-> assert_chk_RWBitWrite;
	wait (`DRIVER.phase == M_DATA_TX);
	ACK_AFTER_ADDR = `DRIVER.last_ack;
	-> assert_chk_addressExists;

    wait (`TARGET.state == 5);
	stretch_time1 = $realtime();
	@(posedge testbench.SCL) stretch_time2 = $realtime();
	CLOCK_STRETCH = ((stretch_time2 - stretch_time1) <= (`TARGET.STRETCH + 2) *  20ns);
	$display("%0t",stretch_time2-stretch_time1);
	-> assert_chk_clockStretch;
	
	wait (`DRIVER.phase == M_ACK_DATA);
	wait (`DRIVER.phase == M_DATA_TX);
	ACK_AFTER_BYTE = `DRIVER.last_ack;
	-> assert_chk_ackAfterByte;

	#25us;
	$finish();
end

always @(assert_chk_ackAfterByte) begin
	chk_ackAfterByte : assert(ACK_AFTER_BYTE) $display("chk_ackAfterByte PASSED");
						else $error("chk_ackAfterByte FAILED");
end

always @(assert_chk_addressExists) begin
	chk_addressExists : assert(ACK_AFTER_ADDR) $display("chk_addressExists PASSED");
						else $error("chk_addressExists FAILED");
end

always @(assert_chk_RWBitWrite) begin
	chk_RWBitWrite : assert(RW_BIT) $display("chk_RWBitWrite PASSED");
					 else $error("chk_RWBitWrite FAILED");
end

always @(assert_chk_clockStretch) begin					
	chk_clockStretch : assert(CLOCK_STRETCH) $display("chk_clockStretch PASSED!");
		else $error("chk_clockStretch FAILED!");
end	

chk_ackAfterData: assert property (ACK_AFTER_DATA) $display("chk_ackAfterData PASSED!");
				  else $error("chk_ackAfterData FAILED!");

endmodule
