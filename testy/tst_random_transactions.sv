`define DRIVER testbench.dv_i2c
`define TARGET testbench.tg_i2c
`define MAIL testbench.dv_i2c.tr_mailbox
`define RAND testbench.i2c_cfg
`define TRANS testbench.test_tr

import transaction_class::*;


module basic_test;

// Deklaracje zmiennych
int NUM_TRANSACTIONS = testbench.NUM_TRANSACTIONS;

initial begin
	test_randomizer tests;
	int i;

	`RAND = new();
	tests = new(7'b0010000);
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


	for (i = 1; i <= NUM_TRANSACTIONS; i++) begin
		if(!tests.randomize()) $error("Test randomization failed");

		$display("\n==================================================");
        $display("[I2C_TEST_RANDOM] TEST %d", i);
        $display("--------------------------------------------------");
        $display("Wylosowana transakcja:");
        $display("Typ transakcji: %s", tests.rw ? "READ":"WRITE");
        $display("Adres Rejestru: %0x", tests.reg_addr);
        if(tests.rw) begin
        	$display("Długość odczytu: %0d", tests.readlen);
        end else begin
        	$display("Długość zapisu: %0d", tests.data_send.size());
	        for(int j = 0; j<tests.data_send.size(); j++) begin
	        	$display("Dane do wysłania, bajt %0d: %8b", j+1, tests.data_send[j]);
	        end
	    end
        $display("==================================================\n");


		`MAIL.put(tests.tr_reg_addr);

		wait(`DRIVER.phase == M_START);
		wait(`DRIVER.phase == M_DONE);

		`MAIL.put(tests.tr);

		wait(`DRIVER.phase == M_START);
		wait(`DRIVER.phase == M_DONE);
	end

	$finish();
end

endmodule