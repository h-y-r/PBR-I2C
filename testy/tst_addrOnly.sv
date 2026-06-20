`define DRIVER testbench.dv_i2c
`define TARGET testbench.tg_i2c
`define MAIL testbench.dv_i2c.tr_mailbox
`define RAND testbench.i2c_cfg
`define TRANS testbench.test_tr

import transaction_class::*;


module tst_addrOnly;

// Deklaracje zmiennych
parameter int NUM_TRANSACTIONS = 20;

event assert_chk_ackAddrOnly;
bit lastAck;

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
	for (int i = 0; i < NUM_TRANSACTIONS; i++) begin

		`DRIVER.addrOnly(7'b0010000);

		wait(`DRIVER.phase == M_START);
		wait(`DRIVER.phase == M_DONE);
		lastAck = `DRIVER.last_ack;
		->assert_chk_ackAddrOnly;
	end
	$finish();
end

always @(assert_chk_ackAddrOnly) begin
	chk_ackAddrOnly: 	assert(lastAck) $display("chk_ackAddrOnly PASSED");
        				else $error("chk_ackAddrOnly FAILED");
end

endmodule