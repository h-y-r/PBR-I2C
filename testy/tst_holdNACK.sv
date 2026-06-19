`define DRIVER testbench.dv_i2c
`define TARGET testbench.tg_i2c
`define MAIL testbench.dv_i2c.tr_mailbox
`define RAND testbench.i2c_cfg
`define TRANS testbench.test_tr

import transaction_class::*;


module tst_holdNACK;

// Deklaracje zmiennych
parameter int NUM_TRANSACTIONS = 20;

event assert_chk_holdNACK;
bit lastAck;
master_phase_e prev_phase;

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

		tr = new(
            .addr(7'b0010000), 
            .rwSet(0), 
            .data_to_send({8'd0})
        );
        `MAIL.put(tr);

        wait (`DRIVER.phase == M_START);

        wait (`DRIVER.phase == M_DONE);

		`DRIVER.burstReadHoldErr(7'b0010000, 2);
		wait (`DRIVER.phase == M_DONE);
	end
	$finish();
end

always@(posedge testbench.SCL) begin
	prev_phase = `DRIVER.phase;
end

always@(`DRIVER.phase) begin
	if(prev_phase == M_ACK_DATA && `DRIVER.phase == M_DATA_RX) begin
		lastAck = `DRIVER.last_ack;
		->assert_chk_holdNACK;
	end
end

always @(assert_chk_holdNACK) begin
	chk_holdNACK: 	assert(lastAck) $display("chk_holdNACK PASSED");
        			else $error("chk_holdNACK FAILED");
end

endmodule